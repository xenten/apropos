/*
 * Copyright (c) 2010, Apropos Project
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. Neither the name Apropos nor the names of its contributors may be used
 *    to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package org.apropos.ui;

import org.apropos.model.RallyModel;
import javafx.scene.control.Label;
import javafx.scene.chart.PieChart;
import javafx.scene.text.Font;
import javafx.scene.paint.Color;
import org.apropos.model.Release;
import org.jfxtras.scene.XCustomNode;
import org.jfxtras.scene.control.XPicker;
import org.jfxtras.scene.layout.XLayoutInfo;
import org.jfxtras.scene.layout.XLayoutInfo.*;
import org.jfxtras.scene.layout.XHBox;
import org.jfxtras.scene.layout.XVBox;

/**
 * @author Stephen Chin
 */
public class AnalyzeModule extends XCustomNode {
    def model = RallyModel.instance;

    def releasePicker:XPicker = XPicker {
        items: bind model.releases
        onIndexChange: function(ind) {rebuildChart()}
    }

    def release = bind releasePicker.selectedItem as Release;

    def names = bind release.packageNames;

    def parentBind = bind parent on replace {
        if (parent != null) {
            rebuildChart();
        }
    }

    var chart:PieChart;
//    on replace {
//        poke(chart, 1000);
//    }

    // hack to workaround the initial chart size issue
//    function poke(chart:PieChart, count:Integer):Void {
//        FX.deferAction(function():Void {
//            chart.requestLayout();
//            (children[0] as XVBox).requestLayout();
//            if (count > 0) {
//                poke(chart, count - 1);
//            }
//        });
//    }

    function rebuildChart():Void {
        def data = for (name in release.packageNames) {
            PieChart.Data {
                label: name
                value: release.getPackageTotals(name)
            }
        }
        chart = PieChart {
            titleFill: Color.WHITE
            titleFont: Font.font(null, 24)
            title: bind "Investment Allocation for {releasePicker.selectedItem}"
            pieLabelFill: Color.WHITE
            data: data
            legendVisible: true
            layoutInfo: XLayoutInfo {hgrow: ALWAYS, vgrow: ALWAYS, vfill: true, hfill: true}
        }
    }
    
    def pickers = XHBox {
        spacing: 8
        content: [
            Label {
                text: "Release Filter:"
                textFill: Color.WHITE
            }
            releasePicker
        ]
    }

    override function create() {
        XVBox {
            spacing: 10
            content: bind [pickers, chart]
        }
    }

}
