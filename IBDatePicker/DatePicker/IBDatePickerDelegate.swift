
import Foundation

public protocol IBDatePickerDelegate {
    func pickerView(pickerView: IBDatePicker, didSelectRow row: Int, inComponent component: Int)
}
