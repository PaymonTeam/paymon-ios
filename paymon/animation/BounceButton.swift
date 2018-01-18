import UIKit

class BounceButton : UIButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.transform = CGAffineTransform(glScalex(GLfixed(0.0), GLfixed(0.0), GLfixed(0.5)))
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}
