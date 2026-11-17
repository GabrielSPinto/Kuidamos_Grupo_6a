# Checklist de handoff RTL — Grupo 6A

Data de preparação: 2026-11-17.  
**Condição:** pacote de fontes/documentação **pronto para revisão**; *não* é handoff final de netlist validada.

| Item | Estado | Evidência |
|---|---|---|
| Interface com reset/start/done especificada | **feito** | `docs/RTL_SPEC.md` |
| Formatos signed, ordem dos bits e vetor `.txt` | **feito** | `docs/RTL_SPEC.md`, `docs/VERIFICATION_PLAN.md` |
| RTL SystemVerilog com FF input/output e 64 mul paralelos | **feito** | `rtl/matmul4x4.sv` |
| Latência 1 ciclo definida e implementada | **feito no código** | RTL, especificação; validar no simulador |
| Testbench autochecking e SVA | **preparado** | `verification/tb_matmul4x4.sv`, `_sva.sv` |
| Modelo Python/NumPy e vetores determinísticos | **feito e testado** | `verification/golden_model.py`, `vectors/` |
| Testes Python e checagens estáticas | **executados e aprovados** | `reports/LOCAL_VALIDATION.md` |
| Simulação real Icarus/VCS (1044 vetores) | **pendente de ferramenta** | usar `make test-rtl`/`scripts/run_vcs.sh` |
| Assertions em VCS | **pendente** | VCS/CIExpert |
| Lint Verilator | **pendente de ferramenta** | `make lint` |
| Síntese DC e relatório de timing/área | **pendente** | escolher `.db` e executar `scripts/run_dc.sh` |
| DFT scan/ATPG e sua cobertura | **outra trilha; pendente** | Felipe / TestMAX |
| Physical e potência | **outra trilha; pendente** | Leonardo / Fusion Compiler |
| Revisão do contrato com Giovana, Felipe e Leonardo | **pendente** | registrar aceite/revisão no GitHub |
| Congelar tag v1.0 RTL | **pendente** | somente após aprovação e regressões |

## Ordem recomendada de integração

1. Gabriel compartilha este pacote e abre PR de interface para Giovana/Felipe/Leonardo.
2. Giovana roda regressão VCS/SVA com vetor, confere protocolo e pede correções por issues.
3. Gabriel corrige RTL, atualiza docs e repete simulação.
4. Executar DC em biblioteca real e entregar netlist, logs, constraints e detalhes de PDK para Felipe e Leonardo.
5. Felipe faz DFT/scan/ATPG; Leonardo prossegue com Physical; qualquer alteração no RTL **invalida** resultados anteriores e deve disparar reruns.
6. Após aceite, criar tag `rtl-v1.0` no GitHub.

**Artefatos que NÃO estão presentes neste pacote:** netlist mapeada, `scan_en/scan_in/scan_out` de netlist DFT, relatórios de cobertura ATPG, layout, métricas de potência/área/frequência verificadas.
