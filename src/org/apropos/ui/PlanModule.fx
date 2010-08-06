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

import org.apropos.model.Story;
import javafx.scene.control.Button;
import javafx.scene.control.TextBox;
import javafx.scene.paint.Color;
import org.jfxtras.scene.control.XTableColumn;
import org.jfxtras.scene.control.XTableView;
import org.jfxtras.scene.control.renderer.RowNumberRenderer;
import org.jfxtras.scene.control.renderer.TextRenderer;
import org.jfxtras.scene.layout.XGrid;
import org.jfxtras.scene.layout.XGridLayoutInfo.*;
import org.jfxtras.scene.layout.XHBox;
import org.jfxtras.scene.layout.XVBox;
import org.jfxtras.scene.paint.ColorUtil;
import org.jfxtras.util.SequenceUtil;
import javafx.scene.control.ScrollView;
import javafx.scene.layout.LayoutInfo;
import javafx.scene.control.Label;
import javafx.scene.Group;
import javafx.scene.shape.Rectangle;
import org.jfxtras.scene.layout.XLayoutInfo;
import javafx.geometry.Insets;

/**
 * @author Stephen Chin
 */
public class PlanModule extends AbstractModulePage {
    var stories:Story[] = bind model.currentRelease.stories;

    var selectedPackage = bind model.selectedPackage;

    public-read var filteredStories = bind model.filter(model.currentRelease.stories);

    var ownerTotals:Double[];

    function calculateOwnerTotals() {
        ownerTotals = for (owner in model.owners) {
            //SequenceUtil.sum(for (story in stories where story.ownerName == owner.getRefObjectName() and story.drafted) story.estimate)
            // TODO: Is this a correct implementation of S19374?
            SequenceUtil.sum(for (story in stories where story.ownerName == owner.getRefObjectName()) story.estimate)
        }
    }

    def parentBind = bind parent on replace {
        if (parent != null) {
            calculateOwnerTotals();
        }
    }

    def allocationFilter = Filter {
        name: "Investment Allocation"
        list: bind model.allocationNames
        selectedIndex: bind model.selectedAllocationIndex with inverse
    };
    def ownerFilter = Filter {
        name: "Owner"
        list: bind for (o in model.owners) o.getDisplayName()
        selectedIndex: bind model.selectedOwnerIndex with inverse
    };

    // TODO: Decide whether to remove this code, as these buttons are (at least
    //       temporarily) not desired in the UI
    def buttons = XHBox {
        spacing: 8
        content: [
//            Button {
//                text: "Auto Assign Features to Owners"
//                action: function() {
//                    for (story in stories) {
//                        story.drafted = true;
//                    }
//                    calculateOwnerTotals();
//                }
//            },
//            Button {
//                text: "Clear Assignments"
//                action: function() {
//                    for (story in stories) {
//                        story.drafted = false;
//                    }
//                    calculateOwnerTotals();
//                }
//            },
            Button {
                text: "update totals"
                action: function() {
                    calculateOwnerTotals();
                }
            }
        ]
    };

    def ownersHeader:XGrid = XGrid {
        hgap: 10
        vgap: 10
        rows:
            row([
                Label {
                    text: "Owner";
                    layoutInfo: LayoutInfo {
                        width: 130
                    }
                },
                Label {
                    text: "Total";
                    layoutInfo: LayoutInfo {
                        width: 80
                    }
                },
                Label {
                    text: "Limit";
                    layoutInfo: LayoutInfo {
                        width: 80
                    }
                }
            ])
    }


    def owners:XGrid = XGrid {
        hgap: 10
        vgap: 10
        rows: for (owner in model.owners) {
            var target:String = model.initialTargets[indexof owner];
            row([
                Label {
                    styleClass: "empasized-text"
                    text: owner.getDisplayName(); 
                    layoutInfo: LayoutInfo {
                        width: 160
                    }
                },
                Label {
                    text: bind "{ownerTotals[indexof owner]}"
                    textFill: bind if (target != "" and Double.valueOf(target) < ownerTotals[indexof owner]) ColorUtil.lighter(Color.RED, .3) else Color.BLACK
                    layoutInfo: LayoutInfo {
                        width: 80
                    }
                },
                TextBox {
                    text: bind target with inverse
                    columns: 5
                },
                ComplianceBarNode {
                    numerator: bind ownerTotals[indexof owner]
                    denominator: bind if (target != "") Double.parseDouble(target)
                                      else 0
                    layoutInfo: XLayoutInfo {
                        width: 80
                        height: 16
                        margin: Insets {top: 5, right: 5, bottom: 5, left: 5}
                    }
                },
                Button {
                    text: "Own Selected Feature"
                    action: function() {
                        def story = filteredStories[table.selectedRow];
                        if (story.owner != owner) {
                            story.owner = owner;
                            story.ownerDisplayName = owner.getDisplayName();
                        }
                        story.drafted = true;
                        calculateOwnerTotals();
                    }
                }
            ])
        }
    }

    def table:XTableView = XTableView {
        rowType: Story {}.getJFXClass()
        rows: bind filteredStories
        rowHeight: 50
        onMouseClicked: function(e) {
            if (e.clickCount == 2) {
                filteredStories[table.selectedRow].browse();
            }
        }
        columns: [
            XTableColumn {
                displayName: "#"
                prefWidth: 20
                id: "rank"
                renderer: RowNumberRenderer {}
            }
            XTableColumn {
                displayName: "ID"
                prefWidth: 20
                id: "id"
                renderer: TextRenderer {}
            }
            XTableColumn {
                displayName: "Theme"
                prefWidth: 80
                id: "parentName"
                renderer: TextRenderer {}
            }
            XTableColumn {
                displayName: "Feature"
                prefWidth: 100
                id: "name"
                renderer: TextRenderer {}
            }
            XTableColumn {
                displayName: "Owner"
                prefWidth: 100
                id: "ownerDisplayName"
                renderer: TextRenderer {}
            }
            XTableColumn {
                displayName: "Est"
                prefWidth: 40
                id: "estimateDisplay"
                renderer: TextRenderer {}
            }
        ]
    }

    init {
        model.selectedAllocationIndex = 0;
        model.selectedOwnerIndex = 0;
        calculateOwnerTotals();
        pageToolBar = PageToolBar {
            leftNodes: [
                allocationFilter,
                ownerFilter
            ]
            rightNodes: CostSelectionNode {}
        };
        pageContent = XHBox {
            spacing: 20
            content: [
                table,
                XVBox {
                    spacing: 15
                    content: [
                        //buttons,
                        Group {
                            content: [
                                Rectangle {
                                    styleClass: "owners-header-background"
                                    width: bind owners.width + 10
                                    height: bind ownersHeader.height + 10
                                },
                                Group {
                                    layoutX: 5
                                    layoutY: 5
                                    content: [
                                        ownersHeader
                                    ]
                                }
                             ]
                        },
                        ScrollView {
                            node: owners
                            layoutInfo:LayoutInfo {
                                width: bind owners.width + 20
                            }
                        }
                    ]
                }
            ]
        }
    }

    public override function initPage():Void {
        allocationFilter.selectedIndex = 0;
        ownerFilter.selectedIndex = 0;
    };
}
