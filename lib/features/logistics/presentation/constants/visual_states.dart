/// Estados visuales para el flujo de cubos de transporte
/// Estados visuales de la aplicación. 
/// Nota: Estos son estados UI, los estados reales del backend están en TrackingStateType
class VisualStates {
  // Estados de Cubo (Visual)
  static const String created = 'Created';
  static const String sent = 'Sent';
  static const String downloading = 'Downloading';
  static const String downloaded = 'Downloaded';

  static String getLabel(String state) {
    switch (state.toUpperCase()) {
      case 'CREATED':
        return 'Despacho en Aduana';
      case 'SENT':
        return 'Tránsito en Bodega';
      case 'DOWNLOADING':
        return 'Recepción en Bodega';
      case 'DOWNLOADED':
        return 'Completado';
      default:
        return state;
    }
  }

  static String getNextState(String currentState) {
    switch (currentState.toLowerCase()) {
      case 'CREATED':
        return sent;
      case 'SENT':
        return downloading;
      case 'DOWNLOADING':
        return downloaded;
      default:
        return currentState;
    }
  }

  static String getActionButtonLabel(String state) {
    switch (state.toUpperCase()) {
      case 'CREATED':
        return 'Enviar a Tránsito';
      case 'SENT':
        return 'Iniciar Recepción';
      case 'DOWNLOADING':
        return 'Finalizar Recepción';
      default:
        return 'Siguiente';
    }
  }

  static String getActionConfirmationTitle(String state) {
    switch (state.toUpperCase()) {
      case 'CREATED':
        return 'Confirmar envío a tránsito';
      case 'SENT':
        return 'Confirmar inicio de recepción';
      case 'DOWNLOADING':
        return 'Confirmar finalización';
      default:
        return 'Confirmar acción';
    }
  }

  static String getActionConfirmationMessage(String state) {
    switch (state.toUpperCase()) {
      case 'CREATED':
        return '¿Está seguro que desea enviar este cubo a tránsito?\n\nEsta acción no se puede deshacer.';
      case 'SENT':
        return '¿Está seguro que desea iniciar la recepción de este cubo?\n\nEsta acción no se puede deshacer.';
      case 'DOWNLOADING':
        return '¿Está seguro que desea finalizar la recepción de este cubo?\n\nEsta acción no se puede deshacer.';
      default:
        return '¿Está seguro que desea continuar?\n\nEsta acción no se puede deshacer.';
    }
  }

  // Estados de Guías en el Cubo (Visual)
  static const String entered = 'ENTERED';
  static const String extracted = 'EXTRACTED';

  static String getGuideActionLabel(String state) {
    switch (state.toUpperCase()) {
      case 'SENT':
        return 'Verificar Guías';
      case 'DOWNLOADING':
        return 'Descargar Guías';
      default:
        return 'Procesar Guías';
    }
  }

  static String getGuideDialogTitle(String state) {
    switch (state.toUpperCase()) {
      case 'SENT':
        return 'Verificar';
      case 'DOWNLOADING':
        return 'Descargar';
      default:
        return 'Procesar';
    }
  }

  static String getGuideSuccessMessage(String state) {
    switch (state.toUpperCase()) {
      case 'SENT':
        return 'Guía verificada';
      case 'DOWNLOADING':
        return 'Guía descargada';
      default:
        return 'Guía procesada';
    }
  }
}