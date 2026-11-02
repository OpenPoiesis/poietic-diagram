import Testing
import PoieticCore
@testable import Diagramming

let DiagramTestNotation = Notation(
    pictograms: [Notation.ReplacementPictogram],
    defaultPictogram: Notation.ReplacementPictogram,
    connectorGlyphs: [Notation.ReplacementConnectorGlyph],
    defaultConnectorGlyph: Notation.ReplacementConnectorGlyph
)

@Suite struct DiagramPresentationBuilderTests {
    let design: Design
    let world: World
    
    var blockA: RuntimeEntity
    var blockB: RuntimeEntity
    var connectorAB: RuntimeEntity
    
    /// Creates a World with two blocks and one connector between them.
    /// Returns the world and the three entity runtime IDs.
    init() throws {

        self.design = Design(metamodel: Metamodel())
        
        let trans = design.createPlane()
        let plane = try design.accept(trans)
        
        self.world = World(plane: plane)
        
        // Set up notation
        //        world.setSingleton(DiagramTestNotation)
        
        // Create two blocks
        let pictogram = DiagramTestNotation.defaultPictogram
        
        self.blockA = world.spawn(
            DiagramBlock(position: Vector2D(100, 100),
                         pictogram: pictogram,
                         label: "Block A",
                         secondaryLabel: "aux A")
        )
        self.blockB = world.spawn(
            DiagramBlock(position: Vector2D(300, 100),
                         pictogram: pictogram,
                         label: "Block B",
                         secondaryLabel: nil)
        )
        
        // Create connector from A to B
        let glyph = DiagramTestNotation.defaultConnectorGlyph
        self.connectorAB = world.spawn(
            DiagramConnector(originID: blockA.runtimeID,
                             targetID: blockB.runtimeID,
                             glyph: glyph)
        )
    }
    
    // MARK: - Tests
    
    @Test func createDiagramFromAll() throws {
        let builder = PresentationBuilder(world: world)
        let diagram = PresentationBuilder.createDiagramFromAll(world: world)

        // Diagram entity has the Diagram component
        #expect(diagram.contains(Diagram.self))
        
        // Diagram depicts all three entities
        let depicted = diagram.outgoing(Depicts.self)
        let depictedIDs = Set(depicted.map { $0.runtimeID })
        #expect(depictedIDs.count == 3)
        #expect(depictedIDs.contains(blockA.runtimeID))
        #expect(depictedIDs.contains(blockB.runtimeID))
        #expect(depictedIDs.contains(connectorAB.runtimeID))
    }
    
    @Test func createDiagramPresentation() throws {
        let builder = PresentationBuilder(world: world)
        let diagram = PresentationBuilder.createDiagramFromAll(world: world)
        let presentation = builder.createPresentation(diagram: diagram)
        
        #expect(presentation.children.count == 3)
        let _: Camera = try #require(presentation.component())
        
        let blocks = presentation.children.filter { $0.contains(BlockNode.self) }
        let connectors = presentation.children.filter { $0.contains(ConnectorNode.self) }
        
        #expect(blocks.count == 2)
        for entity in blocks {
            #expect(entity.containsRelationship(RepresentationOf.self))
        }
        #expect(connectors.count == 1)
        for entity in connectors {
            #expect(entity.containsRelationship(RepresentationOf.self))
        }
    }
    
    @Test func createBlockNode() throws {
        let builder = PresentationBuilder(world: world)
        let diagram = PresentationBuilder.createDiagramFromAll(world: world)
        let presentation = builder.createPresentation(diagram: diagram)
        
        let node: RuntimeEntity = try #require(blockA.incoming(RepresentationOf.self).first)
        
        #expect(node.contains(PresentationNode.self))
        #expect(node.contains(BlockNode.self))
        #expect(node.contains(LocalPosition.self))
        #expect(node.contains(CollisionShape.self))

        let pictogramNode: RuntimeEntity = try #require(node.target(PresentationNode.Pictogram.self))

        #expect(pictogramNode.contains(PictogramNode.self))
    }

    @Test func createConnectorNode() throws {
        // This test assumes only one presentation per diagram
        let builder = PresentationBuilder(world: world)
        let diagram = PresentationBuilder.createDiagramFromAll(world: world)
        let _ = builder.createPresentation(diagram: diagram)
        
        let node: RuntimeEntity = try #require(connectorAB.incoming(RepresentationOf.self).first)
        
        #expect(node.contains(PresentationNode.self))
        #expect(node.contains(ConnectorNode.self))

        let nodeA: RuntimeEntity = try #require(blockA.incoming(RepresentationOf.self).first)
        let nodeB: RuntimeEntity = try #require(blockB.incoming(RepresentationOf.self).first)

        #expect(node.containsRelationship(ConnectorNode.Origin.self, to: nodeA.runtimeID))
        #expect(node.containsRelationship(ConnectorNode.Target.self, to: nodeB.runtimeID))
    }

    @Test func despawnPresentationWhenDiagramDespawns() throws {
        // Tests whether relationships are correctly set
        let builder = PresentationBuilder(world: world)
        let diagram = PresentationBuilder.createDiagramFromAll(world: world)
        let presentation = builder.createPresentation(diagram: diagram)
        
        let entities: [RuntimeEntity] = Array(world.query(PresentationNode.self))
        #expect(!entities.isEmpty)

        world.despawn(diagram)
        
        #expect(!world.contains(presentation))
        let noEntities: [RuntimeEntity] = Array(world.query(PresentationNode.self))
        #expect(noEntities.isEmpty)
    }
}
