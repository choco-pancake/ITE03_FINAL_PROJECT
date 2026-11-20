{{flutter_js}}
{{flutter_build_config}}

const isLocalDevelopment =
    window.location.hostname === 'localhost' ||
    window.location.hostname === '127.0.0.1';

_flutter.loader.load({
  config: isLocalDevelopment
      ? {renderer: 'canvaskit', canvasKitForceCpuOnly: true}
      : {},
});
