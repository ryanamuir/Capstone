

import SwiftUI
import Combine

struct TimerPickerView: UIViewRepresentable {
    @Binding var hrs: Int
    @Binding var mins: Int
    @Binding var secs: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        picker.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        uiView.selectRow(hrs, inComponent: 0, animated: false)
        uiView.selectRow(mins, inComponent: 1, animated: false)
        uiView.selectRow(secs, inComponent: 2, animated: false)
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        let parent: TimerPickerView

        init(_ parent: TimerPickerView) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 3 // hours, minutes, seconds
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 24 // hours
            case 1: return 60 // minutes
            case 2: return 60 // seconds
            default: return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            // Adjust width based on the component
            let totalWidth = pickerView.bounds.width
            return totalWidth / 3
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch component {
            case 0: return "\(row) h"
            case 1: return "\(row) m"
            case 2: return "\(row) s"
            default: return nil
            }
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.hrs = row
            case 1: parent.mins = row
            case 2: parent.secs = row
            default: break
            }
        }
    }
}


struct RestTimer: View {
    @State private var hrs = 0
    @State private var mins = 0
    @State private var secs = 0

    var body: some View {
        NavigationStack {
            VStack {
                Text("Selected Time: \(hrs)h \(mins)m \(secs)s")
                    .padding().font(.title2)
                
                TimerPickerView(hrs: $hrs, mins: $mins, secs: $secs)
                    .frame(height: 200) // Adjust height as needed
                
                
                HStack {
                    Button {
                        // Cancel action
                    } label: {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 100, height: 100) // Consistent circle size
                            .overlay(
                                Text("Cancel")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            )
                    }
                    .padding()
                    .disabled(true)
                    
                    
                    Spacer()
                    
                    //NAVIGATES TO THE COUNTDOWN WHEN THE START BUTTON IS HIT
                    NavigationLink(destination: RestTimeDisplay(hrs: hrs,mins: mins,secs: secs)) {
                        Circle()
                            .fill(Color.green.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("Start")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            )
                            .padding()
                    }
                }
                .padding(.horizontal)
                
            }.navigationTitle("Rest Timer")
        }
        
    }
}


struct RestTimeDisplay: View {
    var hrs:Int
    var mins:Int
    var secs:Int
    
    @State private var totalSeconds = 0
    @State private var initialSeconds = 0
    
    @State private var timerPublisher = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var startDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    private func convertToSeconds(_ hrs: Int, _ mins: Int, _ secs: Int) -> Int {
        hrs * 3600 + mins * 60 + secs
    }
    
    var formattedTime: String {
        let currentSeconds = max(Int(progress * CGFloat(initialSeconds)), 0)
        let h = currentSeconds / 3600
        let m = (currentSeconds % 3600) / 60
        let s = currentSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
    
    @State private var progress: CGFloat = 1.0
    
    var body: some View {
        VStack {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .orange.opacity(0.8), radius: 4, x: 0, y: 0)
                .overlay {
                    Text(formattedTime)
                        .font(.largeTitle)
                }
                .frame(width: 250,height: 250 )
                .onAppear {
                    initialSeconds = convertToSeconds(hrs, mins, secs)
                    startDate = Date()
                }
                .onReceive(timerPublisher) { _ in
                    let elapsed = Date().timeIntervalSince(startDate)
                    let remaining = max(Double(initialSeconds) - elapsed, 0)
                    progress = CGFloat(remaining) / CGFloat(initialSeconds)
                    
                    if remaining <= 0 {
                        timerPublisher.upstream.connect().cancel()
                        progress = 0
                        dismiss()
                        
                    }
                }
        }
    }
}




struct Timer_Previews: PreviewProvider {
    static var previews: some View {
        RestTimer()
    }
}


struct DisplayTimer_Previews: PreviewProvider {
    static var previews: some View {
        RestTimeDisplay(hrs: 0, mins: 0, secs: 20)
    }
}



