/// Short motivational lines shown on Home, one per day (deterministic by
/// day-of-year so it's stable across app opens on the same day, but
/// changes every day). Mixes general-habit encouragement with
/// trading-discipline framing, matching the app's two habit domains.
const List<String> motivationalQuotes = [
  "Pequeños pasos repetidos cada día superan a los grandes planes que nunca empiezan.",
  "La disciplina es elegir lo que más quieres por encima de lo que quieres ahora.",
  "No llegas a la altura de tus metas, caes al nivel de tus sistemas. Confía en el sistema.",
  "Un día más presentándote es un ladrillo más en la pared.",
  "La operación que no tomaste porque rompía tus reglas también es una victoria.",
  "La constancia se acumula en silencio, hasta que un día lo cambia todo.",
  "Tu racha no es la meta - que el hábito se vuelva automático sí lo es.",
  "Protege tu capital y tu constancia de la misma manera.",
  "Cada check de hoy es prueba de la persona en la que te estás convirtiendo.",
  "Un día perdido no es un fracaso. Dos seguidos ya es un patrón - vigílalo.",
  "Planea la operación, opera el plan, registra el resultado. Siempre.",
  "El progreso no es una línea recta, pero sí necesita una dirección.",
  "No necesitas motivación si el hábito ya está programado.",
  "El mercado seguirá ahí mañana. Tu disciplina también debería.",
  "Hazlo hoy para que tu yo futuro no tenga que recuperar el tiempo perdido.",
  "Las acciones aburridas y repetidas construyen lo que otros llaman suerte.",
  "La gestión de riesgo es un hábito, no una reacción.",
  "Preséntate los días en que no tienes ganas - ese es todo el juego.",
  "Tu yo futuro está observando lo que haces ahora mismo.",
  "Los hábitos son votos por la identidad que estás construyendo.",
];

String quoteOfTheDay([DateTime? now]) {
  final today = now ?? DateTime.now();
  final dayOfYear = int.parse(
    '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}',
  );
  final index = dayOfYear % motivationalQuotes.length;
  return motivationalQuotes[index];
}
