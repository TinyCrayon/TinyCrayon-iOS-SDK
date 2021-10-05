//
//  FGCGraph.hpp
//  TinyCrayon
//
//  Created by Xin Zeng on 11/15/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef FGCGraph_hpp
#define FGCGraph_hpp

#import <opencv2/opencv.hpp>
#include <stdio.h>

template <class TWeight> class FGCGraph
{
public:
    FGCGraph();
    FGCGraph( unsigned int vtxCount, unsigned int edgeCount );
    ~FGCGraph();
    void create( unsigned int vtxCount, unsigned int edgeCount );
    int addVtx();
    void addEdges( int i, int j, TWeight w, TWeight revw );
    void addTermWeights( int i, TWeight sourceW, TWeight sinkW );
    TWeight maxFlow();
    bool inSourceSegment( int i );
private:
    class Vtx
    {
    public:
        Vtx *next; // initialized and used in maxFlow() only
        int parent;
        int first;
        int ts;
        int dist;
        TWeight weight;
        uchar t;
    };
    class Edge
    {
    public:
        int dst;
        int next;
        TWeight weight;
    };
    
    std::vector<Vtx> vtcs;
    std::vector<Edge> edges;
    TWeight flow;
};

#endif /* FGCGraph_hpp */
