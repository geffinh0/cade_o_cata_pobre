package com.example.apstransporte.data.remote

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object RetrofitClient {

    // 10.0.2.2 e o endereco que o EMULADOR Android usa para acessar o
    // localhost da maquina host. Testando em celular fisico, troque pelo IP
    // da maquina que roda o middleware na mesma rede Wi-Fi (ex: 192.168.0.10).
    private const val BASE_URL = "http://10.0.2.2:3000/"

    val apiService: ApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ApiService::class.java)
    }
}
