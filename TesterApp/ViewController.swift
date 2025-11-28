//
//  ViewController.swift
//  TesterApp
//
//  Created by Daniel Ruiz on 4/10/25.
//

import Cocoa
import WallpaperMac // Cambia 'WallpaperMac' por el nombre de tu target de salvapantallas

class ViewController: NSViewController {
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // 🚀 NUEVO CÓDIGO: Asegura que la ventana tiene un tamaño razonable
        if let window = self.view.window {
            let preferredSize = NSSize(width: 1024, height: 800)
            window.contentMinSize = preferredSize
            
            // Si la ventana es más pequeña que el tamaño preferido, la redimensiona
            if window.frame.size.width < preferredSize.width ||
               window.frame.size.height < preferredSize.height {
                
                let screenFrame = NSScreen.main?.visibleFrame ?? window.frame
                let newOriginX = screenFrame.midX - preferredSize.width / 2
                let newOriginY = screenFrame.midY - preferredSize.height / 2
                
                window.setFrame(NSRect(x: newOriginX, y: newOriginY,
                                       width: preferredSize.width, height: preferredSize.height),
                                display: true, animate: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ... (El resto del código de inicialización de SalvapantallasView) ...
        guard let screensaverView = SalvapantallasView(frame: self.view.bounds, isPreview: false) else {
            print("ERROR: No se pudo inicializar SalvapantallasView.")
            return
        }
        
        self.view.addSubview(screensaverView)
        screensaverView.autoresizingMask = [.width, .height]
        //screensaverView.startAnimation()
    }
}
