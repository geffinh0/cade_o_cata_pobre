package com.example.apstransporte.data.model

// Modelos que espelham (de forma simplificada) o formato retornado pela
// API Olho Vivo e repassado pelo middleware.

data class Linha(
    val cl: Int,      // codigo interno da linha
    val lc: Boolean,  // se e circular
    val lt: String,   // letreiro
    val sl: Int,      // sentido (1 = principal, 2 = secundario)
    val tl: Int,      // tipo da linha
    val tp: String,   // nome do terminal principal
    val ts: String    // nome do terminal secundario
)

data class Parada(
    val cp: Int,      // codigo da parada
    val np: String,   // nome da parada
    val py: Double,   // latitude
    val px: Double    // longitude
)

data class Veiculo(
    val p: String,    // prefixo do veiculo
    val a: Boolean,   // se e acessivel
    val ta: String,   // timestamp da posicao (ISO 8601)
    val py: Double,   // latitude
    val px: Double    // longitude
)

data class PosicaoLinha(
    val hr: String,
    val vs: List<Veiculo>
)

data class PosicaoEvento(
    val codigoLinha: String,
    val dados: PosicaoLinha,
    val timestamp: Long
)

data class PrevisaoVeiculo(
    val p: String,
    val t: String,    // horario previsto de chegada
    val py: Double,
    val px: Double
)

data class PrevisaoLinha(
    val c: String,
    val cl: Int,
    val sl: Int,
    val qv: Int,      // quantidade de veiculos com previsao
    val vs: List<PrevisaoVeiculo>
)

data class ParadaPrevisao(
    val cp: Int,
    val np: String,
    val py: Double,
    val px: Double,
    val l: List<PrevisaoLinha>
)
