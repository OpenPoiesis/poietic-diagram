//
//  Notation+StockFlow.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

public let DefaultStockFlowConnectorGlyphs: [ConnectorGlyph] = [
    ConnectorGlyph(
        name: "default",
        kind: .thin(ConnectorGlyph.Thin(
            headType: .none,
            tailType: .none)),
        headSize: 0.0,
        tailSize: 0.0,
        lineType: .curved
    ),

    ConnectorGlyph(
        name: "Parameter",
        kind: .thin(ConnectorGlyph.Thin(
                headType: .stick,
                tailType: .ball)),
        headSize: 10.0,
        tailSize: 5.0,
        lineType: .curved
    ),
    ConnectorGlyph(
        name: "Flow",
        kind: .fat(ConnectorGlyph.Fat(
                headType: .regular,
                tailType: .none,
                width: 10.0,
                joinType: .round)),
        headSize: 20.0,
        tailSize: 0.0,
        lineType: .straight
    ),
]

