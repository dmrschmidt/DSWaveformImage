import Foundation
import AVFoundation
import UIKit
import DSWaveformImage

class RecordingViewController: UIViewController {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var waveformView: WaveformLiveView!
    @IBOutlet weak var styleSelector: UISegmentedControl!
    
    private let audioManager: SCAudioManager!
    private let imageDrawer: WaveformImageDrawer!

    required init?(coder: NSCoder) {
        audioManager = SCAudioManager()
        imageDrawer = WaveformImageDrawer()

        super.init(coder: coder)

        audioManager.recordingDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        waveformView.configuration = waveformView.configuration.with(
            backgroundColor: .lightGray.withAlphaComponent(0.1),
            style: styleForSelection(index: styleSelector.selectedSegmentIndex)
        )
        audioManager.prepareAudioRecording()
    }

    @IBAction func didChangeStyle(_ sender: UISegmentedControl) {
        waveformView.configuration = waveformView.configuration.with(
            style: styleForSelection(index: sender.selectedSegmentIndex)
        )
    }

    @IBAction func didChangeSilence(_ sender: UISwitch) {
        waveformView.shouldDrawSilencePadding = sender.isOn
    }

    @IBAction func didChangeDampeningPercentage(_ sender: UISlider) {
        waveformView.configuration = waveformView.configuration.with(
            dampening: waveformView.configuration.dampening?.with(percentage: sender.value)
        )
    }

    @IBAction func didChangeDampeningSides(_ sender: UISegmentedControl) {
        waveformView.configuration = waveformView.configuration.with(
            dampening: waveformView.configuration.dampening?.with(
                sides: sideForSelection(index: sender.selectedSegmentIndex)
            )
        )
    }

    @IBAction func didTapRecording() {
        if audioManager.recording() {
            audioManager.stopRecording()
            recordButton.setTitle("Start Recording", for: .normal)
        } else {
            waveformView.reset()
            audioManager.startRecording()
            recordButton.setTitle("Stop Recording", for: .normal)
        }
    }

    private func styleForSelection(index: Int) -> Waveform.Style {
        switch index {
        case 0: return .filled(.red)
        case 1: return .gradient([.red, .yellow])
        case 2: return .striped(.init(color: .red, width: 3, spacing: 3))
        default: fatalError()
        }
    }

    private func sideForSelection(index: Int) -> Waveform.Dampening.Sides {
        switch index {
        case 0: return .left
        case 1: return .right
        case 2: return .both
        default: fatalError()
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
        recordButton.setTitle("Start Recording", for: .normal)
    }

    func audioManager(_ manager: SCAudioManager!, didUpdateRecordProgress progress: CGFloat) {
        print("current power: \(manager.lastAveragePower()) dB")
        let linear = 1 - pow(10, Float(0) / 20)
        waveformView.samples.append(linear)
    }
}
