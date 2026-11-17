# Subir o pacote no GitHub

Extraia este `.zip` (a **raiz do repositório** é a pasta que contém `README.md`):

```bash
cd Grupo6A_MatMul_RTL
git init
git add .
git commit -m "feat(rtl): matmul 4x4 baseline, golden vectors, tests and handoff"
git branch -M main
# Crie um repositório remoto vazio no GitHub e troque a URL abaixo:
git remote add origin https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
git push -u origin main
```

Depois: GitHub → **Settings → Collaborators and teams** → convide os três membros; ajuste visibilidade e permissões conforme decisão do grupo. A aba **Actions** deve executar `Grupo 6A - RTL validation` com Icarus, Verilator e testes Python. Uma falha na CI **não equivale** a validação aprovada: corrigir, registrar nova evidência e só então liberar handoff final.

Configure revisão por Pull Request para mudanças em `rtl/`, `constraints/` ou contrato de interface. A versão de síntese/DFT/Physical deve referenciar um hash Git ou tag específica para rastreabilidade.
