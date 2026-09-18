package com.example.apstransporte.data.remote

import com.example.apstransporte.data.model.Linha
import com.example.apstransporte.data.model.Parada
import com.example.apstransporte.data.model.ParadaPrevisao
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

// Interface Retrofit que fala com o NOSSO middleware (nao diretamente com a
// API Olho Vivo) - o app nunca deve guardar o token da SPTrans.
interface ApiService {

    @GET("linhas")
    suspend fun buscarLinhas(@Query("termo") termo: String): List<Linha>

    @GET("paradas")
    suspend fun buscarParadas(@Query("termo") termo: String): List<Parada>

    @GET("previsao/{codigoParada}")
    suspend fun previsaoParada(@Path("codigoParada") codigoParada: Int): ParadaPrevisao
}
