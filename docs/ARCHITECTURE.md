# Microarquitetura — MatMul 4×4 totalmente paralela

```text
                   matrix_a[127:0]    matrix_b[127:0]
                           |               |
                       +---v---+       +---v---+
    clk / rst_n / start | A REG |       | B REG |   128 FF cada
                       +---+---+       +---+---+
                           |               |
                           +-------+-------+
                                   |
                       +-----------v-----------+
                       | 16 resultados paralelos|
                       | cada um: 4 mul signed  |
                       | 8x8→16, sign extension |
                       | 2 níveis de soma int32 |
                       +-----------+-----------+
                                   |
                           +-------v-------+
                           | C REG 512 bits|
                           +-------+-------+
                                   |
                            matrix_c[511:0]

       busy_q (1 FF) + done (1 FF) controlam captura/conclusão.
```

**Estrutura lógica conceptual:** 64 produtos signed8×signed8 e 16 somas de quatro parcelas. A síntese pode transformar essa descrição por otimização; não é contagem garantida de células físicas. Registradores arquiteturais: 2×128 + 512 + 1 (busy) + 1 (done) = **770 bits** antes das otimizações/inserção de scan. A área física e temporização precisam ser medidas no DC/Physical.

O código usa `generate` para instanciar 4 linhas × 4 colunas de lógica aritmética. Os operandos de cada elemento C são selecionados dos barramentos de entrada *registrados*, evitando dependência das portas que mudem durante a operação.

**Arithmetic widths:** 8 × 8 = 16 signed; 16→32 com extensão do bit de sinal; soma em 32, sem saturação. A soma exata varia de -65024 a 65536.

**Ponto crítico previsível:** caminho registro A/B → multiplicadores → árvore de adição → registro C. A frequência não pode ser inferida de simulação RTL; depende do PDK, células, carga e restrições.

**Escopo educacional:** sem integração obrigatória com a NPU/ISP/placa Luckfox; unidades definidas para futura adaptação e reuso.
