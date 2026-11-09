defmodule Ciudad do
  @enforce_keys [:id, :nombre, :habitantes]
  defstruct [:id, :nombre, :habitantes]
  # id, nombre: String
  #habitantes: entero
end

defmodule Movimiento do
  @enforce_keys [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  # codigo, id_ciudad: String
  # hora_inicio, hora_final: Time
  # magnitud, profundidad: float
end
