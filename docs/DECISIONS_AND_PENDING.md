# Decisões técnicas (v0.1) e confirmações pendentes

## Decidido e implementado

| Tema | Escolha | Por quê |
|---|---|---|
| Reset | `rst_n` síncrono ativo baixo | simples para um clock, evita reset assíncrono físico |
| Pedido | `start` pulso 1 ciclo, só aceito ocioso | interface mínima, sem fila |
| Conclusão | `done` pulso 1 ciclo em resultado registrado | sincroniza Scoreboard/usuário |
| Busy | interno `busy_q`; `start` enquanto ocupado é descartado | evita sobrescrever operandos |
| Matriz | row-major, elemento (0,0) nos bits baixos | cálculo e empacotamento intuitivos |
| A/B | 16 elementos signed int8 por barramento 128-bit | escopo fixado no planejamento |
| C | 16 elementos signed int32 por barramento 512-bit | sem saturação e sem overflow |
| Microarquitetura | 64 mul em paralelo, soma balanceada, 1 ciclo | escopo original sem pipeline |
| Memória | só FFs, sem SRAM nem blackbox | baixo risco para DFT e síntese |
| Scan | não adicionar portas manuais no RTL | scan deve ser inserido no fluxo DFT sobre netlist |
| Clock | único posedge; 10ns inicial em SDC | referência para relatórios, não meta garantida |

## Precisam de acordo do grupo / medições

1. **Giovana (Verification):** aceitar `rst_n` síncrono, edge N/N+1, start descartado se busy, mapeamento row-major e arquivos de vetor. Se quiser `valid/ready` ou mudar protocolo, discutir **antes** de integrar.
2. **Felipe (DFT):** confirmar que scan ports **não** são necessários na interface RTL funcional. Inserção de `scan_en/scan_in/scan_out` e 2–4 cadeias deve ocorrer em DFT após a netlist. A meta interna >=95% stuck-at e corner `ss_125c` ainda precisam de prova por relatório.
3. **Leonardo (Physical):** confirmar caminho real do PDK/library `.db`, corner `ss_125c`, constraints de I/O, carga/pinout e ferramentas. Não deduzir área/potência sem relatórios.
4. **Orientação:** confirmar aceitação de 4×4 paralelo sem pipeline (planejamento a princípio aprovado) e regra de revisão da meta 100 MHz se não fechar.

Decisões acima são **propostas concretizadas em uma implementação**, não declarações de aprovação formal do professor ou dos demais membros. Alterações no contrato precisam de comunicação e rerun de simulação/DFT/síntese/physical.
