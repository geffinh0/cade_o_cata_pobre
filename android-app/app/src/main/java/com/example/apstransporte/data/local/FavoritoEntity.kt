package com.example.apstransporte.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favoritos")
data class FavoritoEntity(
    @PrimaryKey val codigoLinha: String,
    val descricaoLinha: String
)
