defmodule Passenger do
  defstruct [:id, :name]

  def new(id, name), do: %Passenger{id: id, name: name}

end
