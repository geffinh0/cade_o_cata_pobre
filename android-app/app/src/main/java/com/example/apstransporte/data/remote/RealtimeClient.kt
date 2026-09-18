package com.example.apstransporte.data.remote

import android.util.Log
import com.example.apstransporte.data.model.PosicaoEvento
import com.google.gson.Gson
import io.socket.client.IO
import io.socket.emitter.Emitter
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import org.json.JSONObject

// Cliente do canal de tempo real (Socket.IO). Mantem uma unica conexao
// persistente com o middleware e expoe as posicoes recebidas como um Flow,
// que a ViewModel coleta e expoe pra UI.
class RealtimeClient(
    private val serverUrl: String = "http://10.0.2.2:3000"
) {
    private var socket: io.socket.client.Socket? = null
    private val gson = Gson()

    fun conectar() {
        if (socket != null) return
        socket = IO.socket(serverUrl)
        socket?.connect()
    }

    fun assinarLinha(codigoLinha: String) {
        socket?.emit("assinar_linha", codigoLinha)
    }

    fun cancelarLinha(codigoLinha: String) {
        socket?.emit("cancelar_linha", codigoLinha)
    }

    fun observarPosicoes(): Flow<PosicaoEvento> = callbackFlow {
        val listener = Emitter.Listener { args ->
            try {
                val json = args[0] as JSONObject
                val evento = gson.fromJson(json.toString(), PosicaoEvento::class.java)
                trySend(evento)
            } catch (e: Exception) {
                Log.e("RealtimeClient", "Erro ao parsear evento de posicao", e)
            }
        }
        socket?.on("posicoes", listener)
        awaitClose { socket?.off("posicoes", listener) }
    }

    fun desconectar() {
        socket?.disconnect()
        socket = null
    }
}
