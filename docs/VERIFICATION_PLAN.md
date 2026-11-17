# Plano de validação e protocolo para Verification (Giovana)

## Escopo dos testes já implementados

- Modelo NumPy independente (`verification/golden_model.py`); segundo oráculo escalar Python no `test_golden_model.py`.
- Vetores determinísticos `.txt`: **44 casos direcionados** (zeros, identidades, rampas, extremos, alternados, one-hot) + **1000 aleatórios**, seed `0x6A2026`.
- Testbench SystemVerilog autochecking: executa os 1044 vetores do Golden Model, compara 512 bits, verifica que `done` não sobe na captura, que sobe na próxima borda, que retorna a zero, que C é retida, e que entradas alteradas depois da captura não interferem.
- Testes de controle adicionais: `start` na borda ocupada é ignorado; reset aborta operação e limpa saídas; nova captura já é possível na borda seguinte à conclusão.
- Check SVA (`verification/matmul4x4_sva.sv`) preparado para **VCS**, incluindo timing do `done`, pulso, captura simultânea, retenção de saída e reset. Não compilar este arquivo com Icarus (SVA concorrente requer suporte adequado).

## Formato de cada linha do vetor

Uma linha, três campos **hexadecimais sem `0x`**, separados por espaços:

```text
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB CCCCC...CCCC
```

- campo 1: 32 dígitos hex (`matrix_a[127:0]`);
- campo 2: 32 dígitos hex (`matrix_b[127:0]`);
- campo 3: 128 dígitos hex (`matrix_c[511:0]`).

Os valores negativos são escritos em complemento de dois dentro de **cada elemento** de 8 ou 32 bits. O primeiro elemento `[0,0]` fica no slice **menos significativo** (à direita do texto hexadecimal). Não colocar comentários/linha em branco no arquivo. Veja `RTL_SPEC.md`.

## Execução sugerida

```bash
make test-model
make test-rtl               # depende de iverilog/vvp
bash scripts/run_vcs.sh     # depende de licença e VCS; SVA habilitadas
```

**Atenção:** o testbench não é um substituto para o plano completo UVM da trilha Verification. É uma validação autochecking inicial e uma base/contrato para integração. O responsável pode reutilizar o Golden Model, vetores e SVA ou integrar novos componentes, contanto que o protocolo seja idêntico.

## Critérios antes de congelar RTL

1. VCS/Icarus sem mismatches para todos os 1044 vetores.
2. Reset, latência, rejeição de start ocupado, pulso done, retenção da saída demonstrados.
3. Nenhuma assertion obrigatória SVA falhando no VCS.
4. Interface e empacotamento aprovados por Verification.
5. Registro de logs e versões de simulador no relatório.

O número de vetores e testes não corresponde a uma porcentagem de *functional coverage*; cobertura funcional precisa ser definida e medida separadamente. Métricas de cobertura de scan são responsabilidade de DFT.
