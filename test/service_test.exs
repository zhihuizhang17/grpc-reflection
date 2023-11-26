defmodule GrpcReflection.ServiceTest do
  @moduledoc false

  use ExUnit.Case

  alias GrpcReflection.Service

  setup do
    # clear state for empty setup and dynamic adding
    Application.put_env(:grpc_reflection, :services, [])
    {:ok, _pid} = Service.start_link()
    :ok
  end

  test "adding a service changes responses" do
    assert Service.list_services() == []
    assert Service.get_by_symbol("helloworld.Greeter") == {:error, "symbol not found"}
    assert Service.get_by_filename("helloworld.Greeter.proto") == {:error, "filename not found"}

    assert :ok == Service.put_services([Helloworld.Greeter.Service])

    assert Service.list_services() == ["helloworld.Greeter"]
    assert {:ok, %{file_descriptor_proto: proto}} = Service.get_by_symbol("helloworld.Greeter")

    assert {:ok, %{file_descriptor_proto: ^proto}} =
             Service.get_by_filename("helloworld.Greeter.proto")
  end

  describe "reflection state testing" do
    setup do
      Service.put_services([
        Helloworld.Greeter.Service,
        Grpc.Reflection.V1.ServerReflection.Service,
        Grpc.Reflection.V1alpha.ServerReflection.Service
      ])
    end

    test "expected services are present" do
      assert Service.list_services() == [
               "helloworld.Greeter",
               "grpc.reflection.v1.ServerReflection",
               "grpc.reflection.v1alpha.ServerReflection"
             ]
    end

    test "method files return service descriptors" do
      assert {:ok, %{file_descriptor_proto: proto}} = Service.get_by_symbol("helloworld.Greeter")

      assert {:ok, %{file_descriptor_proto: ^proto}} =
               Service.get_by_symbol("helloworld.Greeter.SayHello")
    end

    test "describing a type returns the type" do
      assert {:ok, %{file_descriptor_proto: proto}} =
               Service.get_by_symbol("helloworld.HelloRequest")

      assert {:ok, %{file_descriptor_proto: ^proto}} =
               Service.get_by_filename("helloworld.HelloRequest.proto")
    end

    test "type with leading period still resolves" do
      assert {:ok, %{file_descriptor_proto: proto}} =
               Service.get_by_symbol(".helloworld.HelloRequest")

      assert {:ok, %{file_descriptor_proto: ^proto}} =
               Service.get_by_filename("helloworld.HelloRequest.proto")
    end
  end
end