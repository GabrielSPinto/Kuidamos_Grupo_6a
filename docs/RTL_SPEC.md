# Especificação funcional e temporal RTL — Grupo 6A

**Versão:** v0.1 (proposta técnica implementada; aprovar em reunião de interface).  
**Módulo:** `matmul4x4` em `rtl/matmul4x4.sv`.  
**Aplicação:** IP independente educacional de aritmética para redes neurais, no contexto KUIDAMOS/CIExpert.

## 1. Escopo e matemática

Para `r,c ∈ {0,1,2,3}`:

`C[r,c] = A[r,0]*B[0,c] + A[r,1]*B[1,c] + A[r,2]*B[2,c] + A[r,3]*B[3,c]`.

- `A[r,c]`, `B[r,c]`: 8 bits **signed** em complemento de dois (`-128..127`).
- `C[r,c]`: 32 bits **signed** (`-65024..65536`, dentro de 32 bits).
- 16 elementos C calculados em paralelo, cada um com quatro produtos `8×8 -> 16` bits signed, extensão **dos produtos** a 32 bits, e soma balanceada de quatro termos.
- **Não há overflow matemático de 32 bits, saturação, arredondamento ou ponto fixo fracionário.**

## 2. Portas

| Nome | Sentido | Tipo SystemVerilog | Significado |
|---|---|---|---|
| `clk` | in | `logic` | Clock único, borda positiva |
| `rst_n` | in | `logic` | Reset **síncrono ativo baixo** |
| `start` | in | `logic` | Pulso de um ciclo que solicita captura |
| `matrix_a` | in | `logic [127:0]` | A completa (16×8 bits) |
| `matrix_b` | in | `logic [127:0]` | B completa (16×8 bits) |
| `done` | out | `logic` | Pulso de um ciclo quando C válido é registrado |
| `matrix_c` | out | `logic [511:0]` | C completa (16×32 bits) |

**Nenhum** `ready`, `valid`, `busy` externo, AXI, SRAM, scan, test_mode ou clock gerado nesta v0.1. O uso da interface é governado por este protocolo, que substitui `ready`.

## 3. Mapeamento de bits (congelado na v0.1)

Ordem **row-major**, com o primeiro elemento nos bits menos significativos. Para `r,c∈0..3`, `n=4*r+c`:

- `A[r,c]` = `$signed(matrix_a[8*n +: 8])`.
- `B[r,c]` = `$signed(matrix_b[8*n +: 8])`.
- `C[r,c]` = `$signed(matrix_c[32*n +: 32])`.

Exemplos: `A[0,0]` = `matrix_a[7:0]`; `A[0,1]` = `[15:8]`; `A[3,3]` = `[127:120]`; `C[0,0]` = `[31:0]`; `C[3,3]` = `[511:480]`.

O vetor hexadecimal `.txt` imprime o barramento como um número usual (nibble mais significativo primeiro): **o primeiro elemento da matriz aparece à direita do texto em hex**. Conferir isso antes de escrever outros modelos.

## 4. Controle e temporização

- **Reset:** `rst_n=0` amostrado em uma borda positiva prevalece sobre `start`; zera A/B registrados, C, `busy_q` e `done`. Como é síncrono, **não** limpa registradores imediatamente entre bordas.
- **Aceitação:** com `rst_n=1`, `busy_q=0`, `start=1` em borda **N**, A e B são capturados simultaneamente; `busy_q` sobe. O requisitante deve emitir **pulso de um ciclo** (não manter `start` alto).
- **Operação:** a matriz C é calculada em um caminho combinacional entre os registradores de entrada e de saída.
- **Conclusão:** na borda **N+1**, C é registrada, `done` fica em 1 e `busy_q` vai a zero. **Latência: um período de clock entre as bordas N e N+1**.
- **Depois:** na borda **N+2**, `done` cai para 0; a saída C permanece com o último resultado até uma nova conclusão ou reset.
- **Pedido durante processamento:** qualquer `start=1` amostrado na borda N+1 com `busy_q=1` é **ignorado** (sem fila nem erro). Um novo pedido pode ser aceito já na borda **N+2**.
- **Pedido repetido:** se o agente mantiver `start=1` por múltiplos ciclos, o hardware poderá aceitar uma segunda operação quando voltar a ficar ocioso. Isso é **uso incorreto** da interface; o agente deve gerar pulsos separados de um ciclo.
- **Entradas após captura:** alterações em `matrix_a`/`matrix_b` entre N e N+1 não mudam o resultado; usamos cópias registradas.
- **Validade da saída:** após reset e antes da primeira conclusão, C vale 0 mas **não deve ser interpretada como cálculo realizado**. Quando `done=1`, C é válida; permanece válida até próximo reset e substituição por outra conclusão.
- **Abortar:** reset durante operação cancela o cálculo e zera C e done.

### Diagrama de ciclos

| Instante | `start` amostrado | interno | `done` após borda | `matrix_c` após borda |
|---|---:|---|---:|---|
| Borda N | 1 | captura A/B e busy=1 | 0 | resultado anterior |
| Borda N+1 | 0 | computa/registrador C, busy=0 | **1** | **novo resultado válido** |
| Borda N+2 | 0 ou 1 novo pulso | ocioso ou nova captura | **0** | retido |
| Borda N+3 (se pedido em N+2) | 0 | próxima conclusão | **1** | novo resultado |

**Observação para SVA:** sinais são amostrados antes das atualizações não bloqueantes; o checker `verification/matmul4x4_sva.sv` faz a compensação correta do ponto de amostragem. A latência funcional continua sendo **N -> N+1**.

## 5. Decisões e justificativas

1. **Reset síncrono ativo baixo (`rst_n`):** um clock único e lógica síncrona simples; não exige células de reset assíncrono, mas o sinal ainda deve ser discutido com DFT.
2. **`done` como pulso:** facilita Scoreboard, evita ambiguidade de leitura e não exige handshake adicional.
3. **Sem `ready`:** IP isolado, máximo de uma operação em processamento. Requisitante deve respeitar o intervalo mínimo de duas bordas entre capturas.
4. **Row-major:** documentação direta, geração NumPy natural (`reshape(4,4)`), evita transposições implícitas.
5. **Produto 16 bits -> extensão para 32:** um produto de dois int8 sempre cabe em signed16. Evita descrever multiplicadores de 32 bits sem sacrificar correção.
6. **Árvore de soma balanceada:** profundidade combinacional menor que uma soma linear de quatro parcelas, preservando paralelismo; desempenho físico ainda não medido.
7. **Sem portas scan no RTL funcional:** DFT pode inserir scan na netlist sintetizada com TestMAX; incluir scan mux manual duplicaria responsabilidade. A pessoa de DFT deve validar essa decisão antes do congelamento definitivo.
8. **Sem pipeline:** mantém a latência original; otimizações que mudem esse requisito necessitam aprovação e revisão de Verification/DFT/Physical.

## 6. Restrições e não objetivos

- Sem SRAM, black boxes, scan flops explícitos, relógio dividido, clock gating, latch, `initial`, delays de síntese ou buffers externos de vídeo.
- Sem NPU completa, CNN, tiling, arranjo sistólico, streaming, dados int16, processamento RTSP/CSI.
- Referência **100 MHz (10ns)** para análise inicial em DC; **não é garantia** de fechamento temporal. Biblioteca/PDK e canto `ss_125c` precisam ser identificados e confirmados no CIExpert.
- Handoff depende de simulação RTL real e revisão do contrato; ver status em `reports/LOCAL_VALIDATION.md`.
