import XCTest
@testable import SwiftRoaring


extension swiftRoaringTests {
    static var allTests : [(String, (swiftRoaringTests) -> () throws -> Void)] {
        return [
            ("testAdd", testAdd),
            ("testRemove", testRemove),
            ("testClear", testClear),
            ("testIterator", testIterator),
            ("testInitRange", testInitRange),
            ("testInitArray", testInitArray),
            ("testInitCapacity", testInitCapacity),
            ("testSelect", testSelect),
            ("testAddingRemoving", testAddingRemoving),
            ("testFree", testFree),
            ("testToArray", testToArray),
            ("testPrinting", testPrinting),
            ("testOptimisations", testOptimisations),
            ("testSubset", testSubset),
            ("testEquals", testEquals),
            ("testFlip", testFlip),
            ("testAnd", testAnd),
            ("testOr", testAnd),
            ("testXor", testAnd),
            ("testAndNot", testAnd),
        ]
    }
}

class swiftRoaringTests: XCTestCase {
    var rbm: RoaringBitmap!

    override func setUp() {
        super.setUp()
        rbm = RoaringBitmap()
    }

    func testAdd() {
        rbm.add(value: 35)
        XCTAssertEqual(rbm.contains(value: 35), true)
    }

    func testRemove() {
        rbm.add(value: 35)
        rbm.remove(value: 35)
        XCTAssertEqual(rbm.contains(value: 35), false)
    }

    func testClear() {
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(value: UInt32(k))
        }
        XCTAssertEqual(rbm.isEmpty(), false)
        rbm.clear()
        XCTAssertEqual(rbm.isEmpty(), true)
    }

    func testIterator() {
        var count = 0
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(value: UInt32(k))
            count += 1
        }
        for i in rbm {
            XCTAssertEqual(rbm.contains(value: i), true)
            count -= 1
            if(count < 0) {break}
        }
        XCTAssertEqual(count, 0)
    }

    func testInitRange(){
        let rbmRange = RoaringBitmap(min: 0,max: 1000,step: 50)
        for k in stride(from: 0, to: 1000, by: 50 ) {
            XCTAssertEqual(rbmRange.contains(value: UInt32(k)), true)
        }
    }

    func testInitCapacity(){
        let rbmCapacity = RoaringBitmap(capacity: 8)
        XCTAssertEqual(rbmCapacity.sizeInBytes(), 5)
    }

    func testInitArray(){
        let array = [0,1,2,4,5,6]
        let rbmArray = RoaringBitmap(values: array.map{ UInt32($0) })
        for i in array {
            XCTAssertEqual(rbmArray.contains(value: UInt32(i)), true)
        }
    }

    func testFlip(){
        rbm.addRangeClosed(min:0, max:500)
        let flip = rbm.flip(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(flip.isEmpty())
        rbm.flipInplace(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(rbm.isEmpty())
    }

    func testEquals(){
        let cpy = rbm.copy()
        XCTAssertTrue(cpy.equals(rbm))
        XCTAssertTrue(cpy == rbm)
        XCTAssertEqual(cpy != rbm, false)
    }

    func testSubset(){
        let cpy = rbm.copy()
        XCTAssertTrue(rbm.isSubset(cpy))
        cpy.add(value: 800)
        XCTAssertTrue(rbm.isStrictSubset(cpy))
        cpy.remove(value: 800)
    }

    func testOptimisations(){
        rbm.addRangeClosed(min:0, max:500)
        XCTAssertTrue(rbm.sizeInBytes() > 0)
        XCTAssertTrue(rbm.shrinkToFit() >= 0)
        XCTAssertTrue(rbm.runOptimize())
        XCTAssertTrue(rbm.removeRunCompression())
    }

    func testPrinting(){
        var rbmap = RoaringBitmap()
        rbmap.add(value: 1)
        rbmap.describe()
        rbmap.print()
    }

    func testToArray(){
        rbm.add(value: 35)
        var array = rbm.toArray()
        for i in rbm {
            if let index = array.index(of: i) {
                array.remove(at: index)
            }
        }
        XCTAssertTrue(array.count == 0)
        XCTAssertTrue(rbm.count() == 1)
    }

    func testFree(){
        // rbm.free()
        // XCTAssertTrue(rbm.count() == 0)
    }

    func testAddingRemoving(){
        rbm.addRangeClosed(min:0, max:500)
        var cpy = rbm.copy()
        _ = cpy.containsRange(start:0, end:501)
        XCTAssertEqual(cpy.maximum(), 500)
        XCTAssertEqual(cpy.minimum(), 0)
        XCTAssertEqual(cpy.rank(value: 499), 500)
        var rbmap = RoaringBitmap()
        rbmap.addRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count() == 11)
        rbmap.removeRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count() == 0)
        rbmap.addRange(min: 0, max: 11)
        rbmap.removeRangeClosed(min: 0, max: 10)
        XCTAssertTrue(rbmap.count() == 0)
        XCTAssertTrue(rbmap.addCheck(value: 0))
        rbmap.addMany(values: [1,2,3])
        XCTAssertTrue(rbmap.count() == 4)
        XCTAssertTrue(rbmap.removeCheck(value: 3))
        XCTAssertTrue(rbmap.count() == 3)
    }

    func testSelect(){
        var cpy = rbm.copy()
        //var element = UInt32(800)
        //TODO: FIX SELECT
        // XCTAssertEqual(cpy.select(rank:500, element: &element), true)
        // XCTAssertEqual(cpy.maximum(), 800)
    }

    func testAnd(){
        var (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 & rbm2
        let andSwift = swiftSet1.intersection(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 &= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let andCardinality = rbm1.andCardinality(rbm2)
        XCTAssertEqual(Int(andCardinality), andSwift.count)

        XCTAssertEqual(rbm1.intersect(rbm2), andSwift.count > 0)   
    }

    func testOr(){
        var (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 | rbm2
        let andSwift = swiftSet1.union(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 |= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let orCardinality = rbm1.orCardinality(rbm2)
        XCTAssertEqual(Int(orCardinality), andSwift.count)

        var (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        var orMany = rbm1.orMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.union(swiftSet2)
        swiftOrMany = swiftOrMany.union(swiftSet3)
        swiftOrMany = swiftOrMany.union(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        orMany = rbm1.orManyHeap([rbm2,rbm3,rbm4])
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        var lazy = rbm3.lazyOr(rbm4, bitsetconversion: false)
        XCTAssertEqual(swiftSet3.union(swiftSet4), Set(lazy.toArray()))
        rbm3.lazyOrInplace(rbm4, bitsetconversion: false)
        rbm3.repairAfterLazy()
        XCTAssertEqual(swiftSet3.union(swiftSet4), Set(rbm3.toArray()))
    }

    func testXor(){
        var (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 ^ rbm2
        let andSwift = swiftSet1.symmetricDifference(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 ^= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let xorCardinality = rbm1.xorCardinality(rbm2)
        XCTAssertEqual(Int(xorCardinality), andSwift.count)

        var (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        let orMany = rbm1.xorMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.symmetricDifference(swiftSet2)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet3)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        var lazy = rbm3.lazyXor(rbm4)
        XCTAssertEqual(swiftSet3.symmetricDifference(swiftSet4), Set(lazy.toArray()))
        rbm3.lazyXorInplace(rbm4)
        rbm3.repairAfterLazy()
        XCTAssertEqual(swiftSet3.symmetricDifference(swiftSet4), Set(rbm3.toArray()))
    }

    func testAndNot(){
        var (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 - rbm2
        let andSwift = swiftSet1.subtracting(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 -= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let andNotCardinality = rbm1.andNotCardinality(rbm2)
        XCTAssertEqual(Int(andNotCardinality), andSwift.count)
    }




    func makeSets() -> (RoaringBitmap, RoaringBitmap, Set<UInt32>, Set<UInt32>){
        let randList1 = makeList(1000)
        let randList2 = makeList(1000)
        let rbm1 = RoaringBitmap(values: randList1)
        let rbm2 = RoaringBitmap(values: randList2)
        let swiftSet1 = Set(randList1)
        let swiftSet2 = Set(randList2)

        return (rbm1, rbm2, swiftSet1, swiftSet2)
    }

    func makeList(_ n: Int) -> [UInt32] {
        return (0..<n).map{ _ in UInt32(Int.random(in: 0 ..< 100000)) }

    
}
}