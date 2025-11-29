//
//  CalorieRingsWidgetBundle.swift
//  CalorieRingsWidget
//
//  Created by Jonatan Borkowski on 29/11/2025.
//

import WidgetKit
import SwiftUI

@main
struct CalorieRingsWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieRingsWidget()
        CalorieRingsWidgetControl()
        CalorieRingsWidgetLiveActivity()
    }
}
