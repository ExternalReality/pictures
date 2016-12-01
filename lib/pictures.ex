defmodule Pictures do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: TaskSupervisor]])
    ]

    opts = [strategy: :one_for_one, name: Pictures.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
