import Testing
import PoieticCore
@testable import Diagramming

let DiagramTestNotation = Notation(
    pictograms: [Notation.ReplacementPictogram],
    defaultPictogram: Notation.ReplacementPictogram,
    connectorGlyphs: [Notation.ReplacementConnectorGlyph],
    defaultConnectorGlyph: Notation.ReplacementConnectorGlyph
)

@Suite struct DiagramSceneComposerTests {
    let design: Design
    let world: World
    
    var blockA: RuntimeEntity
    var blockB: RuntimeEntity
    var connectorAB: RuntimeEntity
    
    /// Creates a World with two blocks and one connector between them.
    /// Returns the world and the three entity runtime IDs.
    init() throws {

        self.design = Design(metamodel: Metamodel())
        
        let trans = design.createFrame()
        let frame = try design.accept(trans)
        
        self.world = World(frame: frame)
        
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
        let composer = DiagramSceneComposer(world: world)
        let diagram = composer.createDiagramFromAll()
        
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
    
    @Test func createDiagramScene() throws {
        let composer = DiagramSceneComposer(world: world)
        let diagram = composer.createDiagramFromAll()
        let scene = composer.createScene(diagram: diagram)
        
        #expect(scene.children.count == 3)
        let _: ViewportState = try #require(scene.component())
        
        let blocks = scene.children.filter { $0.contains(BlockCanvasNode.self) }
        let connectors = scene.children.filter { $0.contains(ConnectorCanvasNode.self) }
        
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
        let composer = DiagramSceneComposer(world: world)
        let diagram = composer.createDiagramFromAll()
        let scene = composer.createScene(diagram: diagram)
        
        let node: RuntimeEntity = try #require(blockA.incoming(RepresentationOf.self).first)
        
        #expect(node.contains(DiagramSceneNode.self))
        #expect(node.contains(BlockCanvasNode.self))
        #expect(node.contains(PositionComponent.self))
        #expect(node.contains(CollisionShape.self))

        let pictogramNode: RuntimeEntity = try #require(node.target(DiagramSceneNode.Pictogram.self))

        #expect(pictogramNode.contains(PictogramCanvasNode.self))
    }

    @Test func createConnectorNode() throws {
        // This test assumes only one scene per diagram
        let composer = DiagramSceneComposer(world: world)
        let diagram = composer.createDiagramFromAll()
        let scene = composer.createScene(diagram: diagram)
        
        let node: RuntimeEntity = try #require(connectorAB.incoming(RepresentationOf.self).first)
        
        #expect(node.contains(DiagramSceneNode.self))
        #expect(node.contains(ConnectorCanvasNode.self))

        let sceneNodeA: RuntimeEntity = try #require(blockA.incoming(RepresentationOf.self).first)
        let sceneNodeB: RuntimeEntity = try #require(blockB.incoming(RepresentationOf.self).first)

        #expect(node.containsRelationship(ConnectorCanvasNode.Origin.self, to: sceneNodeA.runtimeID))
        #expect(node.containsRelationship(ConnectorCanvasNode.Target.self, to: sceneNodeB.runtimeID))
    }

    @Test func despawnSceneWhenDiagramDespawns() throws {
        // Tests whether relationships are correctly set
        let composer = DiagramSceneComposer(world: world)
        let diagram = composer.createDiagramFromAll()
        let scene = composer.createScene(diagram: diagram)
        
        let entities: [RuntimeEntity] = Array(world.query(DiagramSceneNode.self))
        #expect(!entities.isEmpty)

        world.despawn(diagram)
        
        #expect(!world.contains(scene))
        let noEntities: [RuntimeEntity] = Array(world.query(DiagramSceneNode.self))
        #expect(noEntities.isEmpty)
    }
}
