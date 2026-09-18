package com.example.apstransporte.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.apstransporte.data.model.Linha
import com.example.apstransporte.data.model.Veiculo
import com.example.apstransporte.repository.TransporteRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class MainViewModel(private val repository: TransporteRepository) : ViewModel() {

    private val _linhas = MutableStateFlow<List<Linha>>(emptyList())
    val linhas: StateFlow<List<Linha>> = _linhas.asStateFlow()

    private val _veiculos = MutableStateFlow<List<Veiculo>>(emptyList())
    val veiculos: StateFlow<List<Veiculo>> = _veiculos.asStateFlow()

    private var linhaAtual: String? = null

    init {
        repository.conectarTempoReal()
        viewModelScope.launch {
            repository.observarPosicoes().collect { evento ->
                if (evento.codigoLinha == linhaAtual) {
                    _veiculos.value = evento.dados.vs
                }
            }
        }
    }

    fun buscarLinhas(termo: String) {
        if (termo.isBlank()) return
        viewModelScope.launch {
            _linhas.value = repository.buscarLinhas(termo)
        }
    }

    fun acompanharLinha(codigoLinha: String) {
        linhaAtual?.let { repository.cancelarLinha(it) }
        linhaAtual = codigoLinha
        _veiculos.value = emptyList()
        repository.assinarLinha(codigoLinha)
    }

    fun favoritar(codigoLinha: String, descricao: String) {
        viewModelScope.launch { repository.favoritar(codigoLinha, descricao) }
    }

    override fun onCleared() {
        linhaAtual?.let { repository.cancelarLinha(it) }
        super.onCleared()
    }
}
