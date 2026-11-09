defmodule Util do
  @moduledoc """
  Módulo con funciones que se reutilizan
  """

  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end
end
