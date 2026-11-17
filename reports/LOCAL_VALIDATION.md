# Relatório de validação local (não confundir com simulação RTL)

**Data:** 2026-11-17.  
**Fonte:** commit ainda não publicado; arquivos entregues neste pacote.

## Executado neste ambiente

- Python `unittest`: testes de NumPy, equivalência com loop escalar independente, valores extremos, identidade, zeros, empacotamento row-major 8/32 bits, formato dos vetores e testes estáticos conservadores do RTL.
- Geração de **1044** vetores: **44 direcionados + 1000 pseudoaleatórios**, seed `0x6A2026`; texto de A/B/C calculado pelo Golden Model.

**Resultado efetivamente obtido:** `Ran 10 tests in 0.032s — OK` (ver `reports/python_test_output.log`). Os **1044 vetores** também foram redecodificados e recomparados com o modelo. SHA-256 dos vetores: `77406647a916d111a377a539061b9d3c9c70c0e84724d4a8e04e37124829aa1a`. Reproduzível com `make test-model` e `make vectors`. Esses testes não interpretam SystemVerilog: o sucesso deles **não prova** que o DUT funciona.

## NÃO executado neste ambiente

- **Simulação RTL real:** `iverilog`, `vvp` e `vcs` não estavam instalados/disponíveis. Tentativa real: `bash scripts/run_iverilog.sh` retornou **127** com `ERROR: iverilog not found` (ver `reports/rtl_sim_attempt.log`).
- **SVA:** precisa de simulador compatível, previsto VCS no CIExpert.
- **Lint HDL:** `verilator` não estava instalado/disponível.
- **Síntese e timing:** `dc_shell` não estava disponível; PDK/lib `.db` exatos ainda não informados.
- **DFT/ATPG e Physical:** pertencem às respectivas trilhas e dependem da netlist/ambiente CIExpert.

**Próxima evidência mandatória:** saída `PASS` do `make test-rtl` (1044 vetores + testes de protocolo), `make lint` e regressão no VCS; anexar logs antes de declarar RTL verificado/sintetizável.
