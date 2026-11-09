Code.require_file("util.exs")

defmodule NodoCliente do
  @nombre_servicio_local :servicio_respuesta
  @servicio_local {@nombre_servicio_local, :nodocliente@localhost}
  @nodo_remoto :nodoservidor@localhost
  @servicio_remoto {:servicio_sismos, @nodo_remoto}

  # Solicitudes en el orden que pide el enunciado
  @solicitudes [
    {:reporte_ciudad, "C01"},
    {:reporte_ciudad, "C03"},
    {:reporte_ciudad, "C99"},
    :reporte_general,
    :fin
  ]

  def main() do
    Util.mostrar_mensaje("PROCESO PRINCIPAL - Cliente de reportes sísmicos")

    @nombre_servicio_local
    |> registrar_servicio()

    establecer_conexion(@nodo_remoto)
    |> iniciar_produccion()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  defp establecer_conexion(nodo_remoto) do
    Node.connect(nodo_remoto)
  end

  defp iniciar_produccion(false),
    do: Util.mostrar_error("No se pudo conectar con el nodo servidor")

  defp iniciar_produccion(true) do
    enviar_mensajes()
    recibir_respuestas()
  end

  defp enviar_mensajes() do
    Enum.each(@solicitudes, &enviar_mensaje/1)
  end

  defp enviar_mensaje(solicitud) do
    send(@servicio_remoto, {@servicio_local, solicitud})
  end

  defp recibir_respuestas() do
    receive do
      :fin ->
        Util.mostrar_mensaje("\n:fin -> el servidor terminó de enviar las respuestas")

      respuesta ->
        Util.mostrar_mensaje("\n" <> respuesta)
        recibir_respuestas()
    end
  end
end

NodoCliente.main()
