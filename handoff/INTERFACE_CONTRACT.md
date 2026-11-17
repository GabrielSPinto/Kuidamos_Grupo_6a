# Contrato de interface para integração RTL ↔ Verification ↔ DFT ↔ Physical

**Arquivo top:** `rtl/matmul4x4.sv` | **módulo:** `matmul4x4`.

**Portas:** `clk, rst_n, start, matrix_a[127:0], matrix_b[127:0], done, matrix_c[511:0]`.

- `clk`: único clock posedge; `rst_n`: reset síncrono ativo baixo, zera todo estado e C.
- `start`: pulso 1 ciclo, capturado se ocioso. Não há `ready`; pedido emitido na borda ocupada é descartado.
- Na borda **N** aceita: A/B capturados. Na borda **N+1**: C registrado e `done` sobe. Na borda **N+2**: `done` desce; possível nova captura N+2.
- `done`: 1 ciclo; C retido até nova conclusão/reset.
- Dados: int8 signed por elemento em A/B, int32 signed por elemento em C; row-major: `slice_in[8*(4*r+c)+:8]`; `slice_out[32*(4*r+c)+:32]`.
- Para todos os 16 elementos: `C[r,c]=Σ A[r,k]*B[k,c]`, k=0..3; sem overflow/saturação.
- Arquitetura: inteiramente paralela, sem pipeline, SRAM, interfaces de vídeo ou registradores test-only.

**Para Verification:** `verification/golden_model.py`, vetores `.txt` e testbench/SVA entregues no diretório. Testar sinais na borda após NBA ou com clocking block; consultar `docs/RTL_SPEC.md` para semântica de amostragem SVA.

**Para DFT:** scan ports não foram colocados manualmente no RTL; adicionar no **netlist/fluxo DFT**, discutindo com Gabriel antes de modificar o top funcional. Clock único, reset síncrono, sem clock gating/memórias.

**Para Physical:** aguardar netlist sintetizada e SDC revisado em CIExpert; `constraints/matmul4x4.sdc` restringe somente o clock interno, e é necessário acordar as demais constraints, corner e lib.
