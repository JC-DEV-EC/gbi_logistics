# Implementación Backend - Control de Versiones

## Headers que recibirá el backend desde la app móvil

El cliente móvil enviará automáticamente estos headers en **todas** las peticiones:

```http
X-App-Version: 1.0.0
X-App-Build: 1  
X-App-Platform: android
X-Client-Type: mobile-app
```

## Como implementar en el backend

### 1. Middleware para verificar versión (Node.js/Express ejemplo)

```javascript
const versionCheck = (req, res, next) => {
  const clientVersion = req.headers['x-app-version'];
  const clientBuild = req.headers['x-app-build'];
  const platform = req.headers['x-app-platform'];

  // Configuración de versiones (esto podría venir de BD)
  const VERSION_CONFIG = {
    minVersion: '1.0.0',
    latestVersion: '1.2.0',
    forceUpdateBelowVersion: '0.9.0'
  };

  // Verificar si es versión muy antigua (forzar actualización)
  if (compareVersions(clientVersion, VERSION_CONFIG.forceUpdateBelowVersion) <= 0) {
    res.set({
      'X-Update-Required': 'true',
      'X-Min-Version': VERSION_CONFIG.minVersion,
      'X-Latest-Version': VERSION_CONFIG.latestVersion,
      'X-Update-Message': 'Su versión es muy antigua. Debe actualizar para continuar.',
      'X-Update-URL': getStoreUrl(platform)
    });
    
    return res.status(426).json({
      code: 426,
      message: 'Upgrade Required',
      messageDetail: 'Debe actualizar la aplicación para continuar'
    });
  }

  // Verificar si hay actualización disponible (opcional)
  if (compareVersions(clientVersion, VERSION_CONFIG.latestVersion) < 0) {
    res.set({
      'X-Update-Available': 'true',
      'X-Latest-Version': VERSION_CONFIG.latestVersion,
      'X-Update-Message': 'Nueva versión disponible con mejoras.',
      'X-Update-URL': getStoreUrl(platform)
    });
  }

  next();
};

function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);
  
  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const part1 = parts1[i] || 0;
    const part2 = parts2[i] || 0;
    
    if (part1 < part2) return -1;
    if (part1 > part2) return 1;
  }
  return 0;
}

function getStoreUrl(platform) {
  switch(platform) {
    case 'android':
      return 'https://play.google.com/store/apps/details?id=com.gbi.logistics';
    case 'ios':
      return 'https://apps.apple.com/app/gbi-logistics/id1234567890';
    default:
      return 'https://gbilogistics.com/download';
  }
}
```

### 2. Ejemplo en PHP/Laravel

```php
<?php

class VersionMiddleware
{
    public function handle($request, Closure $next)
    {
        $clientVersion = $request->header('X-App-Version');
        $clientBuild = $request->header('X-App-Build');
        $platform = $request->header('X-App-Platform');

        // Configuración desde config o BD
        $config = config('app.version_control');
        
        // Verificar actualización forzada
        if (version_compare($clientVersion, $config['force_update_below']) <= 0) {
            return response()->json([
                'code' => 426,
                'message' => 'Upgrade Required',
                'messageDetail' => 'Debe actualizar la aplicación para continuar'
            ], 426)->withHeaders([
                'X-Update-Required' => 'true',
                'X-Min-Version' => $config['min_version'],
                'X-Latest-Version' => $config['latest_version'],
                'X-Update-Message' => 'Su versión es muy antigua. Debe actualizar.',
                'X-Update-URL' => $this->getStoreUrl($platform)
            ]);
        }

        // Verificar actualización opcional
        if (version_compare($clientVersion, $config['latest_version']) < 0) {
            $response = $next($request);
            return $response->withHeaders([
                'X-Update-Available' => 'true',
                'X-Latest-Version' => $config['latest_version'],
                'X-Update-Message' => 'Nueva versión disponible con mejoras.',
                'X-Update-URL' => $this->getStoreUrl($platform)
            ]);
        }

        return $next($request);
    }
    
    private function getStoreUrl($platform)
    {
        return match($platform) {
            'android' => 'https://play.google.com/store/apps/details?id=com.gbi.logistics',
            'ios' => 'https://apps.apple.com/app/gbi-logistics/id1234567890',
            default => 'https://gbilogistics.com/download'
        };
    }
}
```

### 3. Ejemplo en C#/.NET

```csharp
public class VersionCheckMiddleware
{
    private readonly RequestDelegate _next;
    private readonly VersionConfig _config;

    public VersionCheckMiddleware(RequestDelegate next, VersionConfig config)
    {
        _next = next;
        _config = config;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var clientVersion = context.Request.Headers["X-App-Version"].FirstOrDefault();
        var platform = context.Request.Headers["X-App-Platform"].FirstOrDefault();

        if (!string.IsNullOrEmpty(clientVersion))
        {
            var versionCheck = CheckVersion(clientVersion);
            
            if (versionCheck.ForceUpdate)
            {
                context.Response.StatusCode = 426;
                context.Response.Headers.Add("X-Update-Required", "true");
                context.Response.Headers.Add("X-Min-Version", _config.MinVersion);
                context.Response.Headers.Add("X-Latest-Version", _config.LatestVersion);
                context.Response.Headers.Add("X-Update-Message", "Debe actualizar la aplicación");
                context.Response.Headers.Add("X-Update-URL", GetStoreUrl(platform));
                
                await context.Response.WriteAsync(JsonSerializer.Serialize(new
                {
                    code = 426,
                    message = "Upgrade Required",
                    messageDetail = "Debe actualizar la aplicación para continuar"
                }));
                return;
            }

            if (versionCheck.UpdateAvailable)
            {
                context.Response.Headers.Add("X-Update-Available", "true");
                context.Response.Headers.Add("X-Latest-Version", _config.LatestVersion);
                context.Response.Headers.Add("X-Update-Message", "Nueva versión disponible");
                context.Response.Headers.Add("X-Update-URL", GetStoreUrl(platform));
            }
        }

        await _next(context);
    }
}
```

## Configuración Recomendada

### Base de datos para configuración dinámica

```sql
CREATE TABLE app_version_control (
    id INT PRIMARY KEY,
    platform VARCHAR(20) NOT NULL, -- 'android', 'ios', 'all'
    min_version VARCHAR(20) NOT NULL,
    latest_version VARCHAR(20) NOT NULL,
    force_update_below VARCHAR(20),
    update_message TEXT,
    store_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Datos ejemplo
INSERT INTO app_version_control VALUES
(1, 'android', '1.0.0', '1.2.0', '0.9.0', 'Nueva versión con mejoras de seguridad', 'https://play.google.com/store/apps/details?id=com.gbi.logistics', true, NOW(), NOW()),
(2, 'ios', '1.0.0', '1.2.0', '0.9.0', 'Nueva versión con mejoras de seguridad', 'https://apps.apple.com/app/gbi-logistics/id1234567890', true, NOW(), NOW());
```

## Flujo de Trabajo

1. **Desarrollo**: Actualizar version en `pubspec.yaml`
2. **Build**: El sistema automáticamente tomará la nueva versión
3. **Deploy Backend**: Actualizar la configuración de versiones en BD
4. **Release**: Publicar en las tiendas
5. **Activar Control**: Activar el control de versiones en backend

## Estados de Versión

- **Compatible**: No se envían headers especiales
- **Actualización Disponible**: `X-Update-Available: true`
- **Actualización Requerida**: `X-Update-Required: true` + Status 426

## Testing

Para probar, puedes simular diferentes versiones modificando temporalmente el `pubspec.yaml`:

```yaml
# Para probar actualización opcional
version: 1.1.0+1

# Para probar actualización forzada  
version: 0.8.0+1
```