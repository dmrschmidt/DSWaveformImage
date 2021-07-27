import Foundation
import AVFoundation
import UIKit
import DSWaveformImage

class RecordingViewController: UIViewController {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var waveformView: UIImageView!

    private let audioManager: SCAudioManager!
    private let imageDrawer: WaveformImageDrawer!

    private var amplitudes: [Float] = []

    required init?(coder: NSCoder) {
        audioManager = SCAudioManager()
        imageDrawer = WaveformImageDrawer()

        super.init(coder: coder)

        audioManager.recordingDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        audioManager.prepareAudioRecording()
    }

    @IBAction func didTapRecording() {
        if audioManager.recording() {
            audioManager.stopRecording()
            recordButton.setTitle("Start Recording", for: .normal)
        } else {
            amplitudes = []
            audioManager.startRecording()
            recordButton.setTitle("Stop Recording", for: .normal)
        }
    }
}

extension RecordingViewController: RecordingDelegate {
    func audioManager(_ manager: SCAudioManager!, didAllowRecording success: Bool) {
        if !success {
            preconditionFailure("Recording must be allowed in Settings to work.")
        }
    }

    func audioManager(_ manager: SCAudioManager!, didFinishRecordingSuccessfully success: Bool) {
        print("did finish recording with success=\(success)")
    }

    func audioManager(_ manager: SCAudioManager!, didUpdateRecordProgress progress: CGFloat) {
        print("current power: \(manager.lastAveragePower()) dB")
        let linear = 1 - pow(10, manager.lastAveragePower() / 20)
        amplitudes.append(linear)

        let amplitudes = amplitudes
        let imageSize = waveformView.bounds.size

        DispatchQueue.global(qos: .userInteractive).async {
            let image = self.imageDrawer.waveformImage(
                from: amplitudes,
                with: .init(size: imageSize)
            )

            DispatchQueue.main.async {
                self.waveformView.image = image
            }
        }
    }
}
