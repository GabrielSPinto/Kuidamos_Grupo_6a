# KUIDAMOS / CIExpert — Grupo 6A — MatMul 4×4 RTL

IP **educacional** de multiplicação matricial **4×4**, com elementos de entrada `int8 signed` e saída `int32 signed`, implementado em **SystemVerilog**. Arquitetura paralela e sem pipeline: as duas matrizes são capturadas juntas, e a matriz de saída fica registrada **uma borda de clock depois**. Não substitui a NPU da startup nem implementa inferência completa.

**Responsáveis**: Gabriel Santos Pinto (RTL); Giovana Ferreira Santos (Verification); Felipe Lopes Gibin Duarte (DFT); Leonardo Santiago Melgaço Silva (Physical).

## Interface v0.1 proposta para congelamento

| Porta | Direção | Bits | Semântica |
|---|---|---:|---|
| `clk` | in | 1 | Clock único, borda positiva |
| `rst_n` | in | 1 | Reset **síncrono**, ativo em 0 |
| `start` | in | 1 | Pulso de **um ciclo**; captura quando o módulo está ocioso |
| `matrix_a` | in | 128 | 16 × int8 signed, por linhas (`row-major`) |
| `matrix_b` | in | 128 | 16 × int8 signed, por linhas (`row-major`) |
| `done` | out | 1 | Pulso de um ciclo, alinhado ao resultado registrado |
| `matrix_c` | out | 512 | 16 × int32 signed, por linhas; retida até novo resultado/reset |

**Cronograma:** pedido aceito na borda **N**; `matrix_c` atualiza e `done=1` após a borda **N+1**. `done` volta a zero após **N+2**. Pedidos em N+1 são ignorados; o pedido seguinte pode ser aceito em N+2. Em `rst_n=0` na borda ativa, todos os registradores e `done` vão a zero. Veja a [especificação integral](docs/RTL_SPEC.md) e o [contrato para Verification](handoff/INTERFACE_CONTRACT.md).

**Importante:** o barramento completo não é um único inteiro signed: cada *slice* de 8/32 bits representa um elemento em complemento de dois.

## Primeiros passos

Requisitos locais: Python 3 + NumPy; para simulação real do RTL: Icarus Verilog (`iverilog` e `vvp`). Verilator é opcional para lint. Para SVA e simulação comercial, use o VCS do ambiente CIExpert.

```bash
python3 -m pip install -r requirements.txt
make test-model           # testa o Golden Model e regras estáticas do código
make test-rtl             # compila e simula o RTL real (Icarus)
make lint                 # Verilator, se disponível
# Alternativamente: make test (test-model + test-rtl)
```

`make test-rtl` regenera **1044 vetores determinísticos** (44 direcionados + 1000 aleatórios), compila o DUT e executa o testbench autochecking. **Uma execução Python não é prova de que o RTL simulou ou sintetizou.** O GitHub Actions (`.github/workflows/rtl-validation.yml`) roda a simulação e o lint automaticamente a cada `push` e PR num runner com ferramentas instaladas.

Para o ambiente CIExpert:

```bash
bash scripts/run_vcs.sh
export TARGET_LIB=/caminho/absoluto/para/a_biblioteca_de_celulas.db
bash scripts/run_dc.sh
```

O script de DC é **baseline**, não substitui ajustes de biblioteca/constraints do laboratório; `100 MHz` é referência para análise e **não** uma frequência comprovadamente atingida. DFT/scan e Physical são executados por seus responsáveis com a netlist/relatórios de síntese. Não há arquivos de scan nem netlist física neste pacote.

## Estrutura

```text
rtl/matmul4x4.sv                  implementação sintetizável do IP
verification/golden_model.py    cálculo independente em NumPy + empacotamento
verification/generate_vectors.py geração determinística de vetores .txt
verification/tb_matmul4x4.sv    testbench autochecking sem SVA (Icarus/VCS)
verification/matmul4x4_sva.sv  asserts concorrentes para VCS
verification/test_*.py        testes do modelo e checagens estáticas
vectors/matmul_vectors.txt     1044 estímulos e resultados esperados
constraints/matmul4x4.sdc     clock nominal 10 ns
scripts/run_*.sh              simulação e síntese (ambiente adequado)
scripts/dc_synth.tcl          baseline Synopsys DC
.github/workflows/           CI de validação RTL com ferramentas livres
docs/                        especificação, arquitetura, plano de testes e status
handoff/                     contratos e checklist para as outras trilhas
reports/                     evidências *locais*, com limitações explícitas
```

## Critério de entrega RTL

- [x] Fonte RTL; contrato funcional/temporal; formato dos barramentos definidos.
- [x] Golden Model NumPy, geração de vetores e testbench autochecking disponíveis.
- [x] Testes locais do **modelo Python e verificações estáticas** executados com sucesso (veja `reports/LOCAL_VALIDATION.md`).
- [ ] Simulação do **RTL real** com Icarus e VCS; regressão SVA VCS — depende de executar em ambiente com simulador.
- [ ] Síntese DC e análise de área/timing — depende de PDK/biblioteca e ferramentas CIExpert.
- [ ] DFT scan/ATPG e implementação física — tarefas das trilhas correspondentes.

**Handoff documental entregue; handoff técnico é condicionado a passar simulação real e revisão das interfaces pelos três responsáveis.** Consulte [`handoff/RTL_HANDOFF_CHECKLIST.md`](handoff/RTL_HANDOFF_CHECKLIST.md).
