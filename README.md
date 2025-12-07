# Polar Dash 🐧

**Polar Dash** es un emocionante juego de estilo _infinite runner_ desarrollado en **Godot Engine 4**. En este juego, controlarás a un pingüino que debe escapar de focas hambrientas mientras recorre un desierto helado infinito generado proceduralmente.

## ❄️ Características Principales

- **Generación de Terreno Procedural**: El suelo nunca es igual. Se genera infinitamente utilizando algoritmos de ruido y curvas suaves para crear colinas orgánicas y desafiantes.
- **Enemigos Dinámicos**: Las focas no solo son obstáculos estáticos; tienen comportamiento de persecución y animaciones de ataque cuando están cerca del jugador.
- **Sistema de Puntuación**: Tu puntuación aumenta a medida que avanzas. ¡Intenta superar tu propio récord!
- **Interfaz de Usuario Completa**: Incluye un menú principal fluido, menú de pausa con superposición transparente y pantalla de Game Over.

## 🎮 Controles

| Acción     | Teclado / Ratón                                                    |
| :--------- | :----------------------------------------------------------------- |
| **Saltar** | Tecla `Espacio` o Clic en el botón de salto en pantalla            |
| **Pausa**  | Tecla `ESC` o Clic en el botón de pausa (esquina superior derecha) |

## 🛠️ Instalación y Ejecución

Para jugar o editar **Polar Dash**, necesitas [Godot Engine 4.x](https://godotengine.org/).

1.  **Clonar el repositorio:**

    ```bash
    git clone https://github.com/tu-usuario/polar-dash.git
    ```

    _(O descarga el código como ZIP y descomprímelo)_

2.  **Importar en Godot:**

    - Abre Godot Engine.
    - Haz clic en **"Importar"**.
    - Navega hasta la carpeta del proyecto y selecciona el archivo `project.godot`.
    - Haz clic en **"Importar y Editar"**.

3.  **Jugar:**
    - Presiona `F5` o el botón de "Reproducir" en la esquina superior derecha del editor para iniciar el juego desde el menú principal.

## 📂 Estructura del Proyecto

El proyecto está organizado de la siguiente manera para facilitar el desarrollo:

- `assets/`: Contiene todos los recursos gráficos (sprites, fondos) y de audio (música, efectos).
- `entities/`: Contiene las escenas y scripts de los objetos del juego.
  - `player/`: Lógica y escena del pingüino.
  - `seal/`: Lógica y escena de los enemigos.
  - `ground/`: Scripts para la generación del terreno (`line_2d_piso.gd`).
- `ui/`: Interfaces de usuario.
  - `menus/`: Menú principal.
  - `overlays/`: Pantallas superpuestas como Pausa y Game Over.
- `scenes/`: Escenas principales del juego (como el mapa de juego `mapa.tscn`).

---

_¡Diviértete deslizándote por el hielo!_ ❄️
