package com.example.apstransporte.repository

import com.example.apstransporte.data.local.FavoritoDao
import com.example.apstransporte.data.local.FavoritoEntity
import com.example.apstransporte.data.model.Linha
import com.example.apstransporte.data.model.ParadaPrevisao
import com.example.apstransporte.data.model.PosicaoEvento
import com.example.apstransporte.data.remote.ApiService
import com.example.apstransporte.data.remote.RealtimeClient
import kotlinx.coroutines.flow.Flow

// Ponto unico que a UI usa: esconde de onde os dados vem (REST direto no
// middleware para buscas pontuais, Socket.IO para posicoes em tempo real,
// Room para dados locais/favoritos).
class TransporteRepository(
    private val api: ApiService,
    private val realtime: RealtimeClient,
    private val favoritoDao: FavoritoDao
) {

    suspend fun buscarLinhas(termo: String): List<Linha> = api.buscarLinhas(termo)

    suspend fun previsaoParada(codigoParada: Int): ParadaPrevisao = api.previsaoParada(codigoParada)

    fun conectarTempoReal() = realtime.conectar()

    fun assinarLinha(codigoLinha: String) = realtime.assinarLinha(codigoLinha)

    fun cancelarLinha(codigoLinha: String) = realtime.cancelarLinha(codigoLinha)

    fun observarPosicoes(): Flow<PosicaoEvento> = realtime.observarPosicoes()

    fun observarFavoritos(): Flow<List<FavoritoEntity>> = favoritoDao.observarFavoritos()

    suspend fun favoritar(codigoLinha: String, descricao: String) =
        favoritoDao.inserir(FavoritoEntity(codigoLinha, descricao))

    suspend fun desfavoritar(favorito: FavoritoEntity) = favoritoDao.remover(favorito)
}
