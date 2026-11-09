Code.require_file("util.exs")
Code.require_file("structs.exs")
Code.require_file("lector.exs")
Code.require_file("coordinador.exs")
Code.require_file("reporte.exs")

defmodule NodoServidor do
  @nombre_servicio_local :servicio_sismos

  def main() do
    Util.mostrar_mensaje("PROCESO SECUNDARIO - Servidor de reportes sísmicos")
    registrar_servicio(@nombre_servicio_local)
    procesar_mensajes()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  # Atiende una solicitud a la vez, así responde en el mismo orden en que llegan
  defp procesar_mensajes() do
    receive do
      {productor, solicitud} ->
        respuesta = procesar_mensaje(solicitud)
        send(productor, respuesta)
        # Llama recursivamente para seguir recibiendo mensajes (también después de :fin)
        procesar_mensajes()
    end
  end

  defp procesar_mensaje(:fin), do: :fin

  defp procesar_mensaje({:reporte_ciudad, id_ciudad}) do
    Coordinador.obtener_datos()
    |> responder_ciudad(id_ciudad)
  end

  defp procesar_mensaje(:reporte_general) do
    Coordinador.obtener_datos()
    |> responder_general()
  end

  defp procesar_mensaje(mensaje), do: "La solicitud \"#{inspect(mensaje)}\" es desconocida."

  defp responder_ciudad({:ok, datos}, id_ciudad), do: Reporte.generar_ciudad(datos, id_ciudad)
  defp responder_ciudad({:error, mensaje}, _id_ciudad), do: mensaje

  defp responder_general({:ok, datos}), do: Reporte.generar_general(datos)
  defp responder_general({:error, mensaje}), do: mensaje
end

NodoServidor.main()
