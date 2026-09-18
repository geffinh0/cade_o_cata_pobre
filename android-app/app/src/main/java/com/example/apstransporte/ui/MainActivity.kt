package com.example.apstransporte.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apstransporte.data.local.AppDatabase
import com.example.apstransporte.data.remote.RealtimeClient
import com.example.apstransporte.data.remote.RetrofitClient
import com.example.apstransporte.repository.TransporteRepository

class MainViewModelFactory(private val repository: TransporteRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        @Suppress("UNCHECKED_CAST")
        return MainViewModel(repository) as T
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val db = AppDatabase.getInstance(applicationContext)
        val repository = TransporteRepository(
            api = RetrofitClient.apiService,
            realtime = RealtimeClient(),
            favoritoDao = db.favoritoDao()
        )

        setContent {
            MaterialTheme {
                val viewModel: MainViewModel = viewModel(factory = MainViewModelFactory(repository))
                TelaPrincipal(viewModel)
            }
        }
    }
}

@Composable
fun TelaPrincipal(viewModel: MainViewModel) {
    var termoBusca by remember { mutableStateOf("") }
    val linhas by viewModel.linhas.collectAsState()
    val veiculos by viewModel.veiculos.collectAsState()

    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Text("Transporte publico em tempo real", style = MaterialTheme.typography.titleLarge)
        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = termoBusca,
            onValueChange = { termoBusca = it },
            label = { Text("Buscar linha (ex: 8000)") },
            modifier = Modifier.fillMaxWidth()
        )
        Button(
            onClick = { viewModel.buscarLinhas(termoBusca) },
            modifier = Modifier.padding(top = 8.dp)
        ) {
            Text("Buscar")
        }

        Spacer(modifier = Modifier.height(16.dp))
        Text("Linhas encontradas", style = MaterialTheme.typography.titleMedium)
        LazyColumn(modifier = Modifier.weight(1f)) {
            items(linhas) { linha ->
                ListItem(
                    headlineContent = { Text(linha.tp) },
                    supportingContent = { Text("Linha ${linha.cl}") },
                    trailingContent = {
                        TextButton(onClick = { viewModel.acompanharLinha(linha.cl.toString()) }) {
                            Text("Acompanhar")
                        }
                    }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
        Text("Onibus em tempo real (${veiculos.size})", style = MaterialTheme.typography.titleMedium)
        LazyColumn(modifier = Modifier.weight(1f)) {
            items(veiculos) { veiculo ->
                ListItem(
                    headlineContent = { Text("Prefixo ${veiculo.p}") },
                    supportingContent = { Text("lat ${veiculo.py}, lon ${veiculo.px}") }
                )
            }
        }
    }
}
