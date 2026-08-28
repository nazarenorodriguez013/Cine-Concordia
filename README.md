# Cine Concordia - Frontend (Angular)

Rama `frontend`. Por ahora contiene **únicamente la sección Hero** de la home.

## Requisitos
- Node.js 18+
- npm

## Uso
```bash
npm install
npm start
```
Abre http://localhost:4200

## Build
```bash
npm run build
```

## Estructura
```
src/
  app/
    app.component.ts          # bootstrap, renderiza <cc-hero>
    app.config.ts
    features/home/components/hero/
      hero.component.ts
      hero.component.html
  assets/
    css/base.css              # design tokens
    css/hero.css              # estilos del hero
    fonts/
    img/spidermanbackdrop.jpg
  index.html
  main.ts
  styles.css
```

Código base tomado de https://github.com/valentin-reboli/Proyecto-Cine
