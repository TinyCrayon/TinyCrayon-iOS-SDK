//
//  KCenterClustering.hpp
//  BlurEffect
//
//  Created by Xin Zeng on 11/7/15.
//  Copyright © 2015 Xin Zeng. All rights reserved.
//

#ifndef KCenterClustering_hpp
#define KCenterClustering_hpp

#include <stdio.h>

class KCenterClustering{
public:
    
    //Output parameters
    
    double MaxClusterRadius;	//maximum cluster radius
    
    int *pClusterIndex;		    //pointer to a vector of length N where the i th element is the
                                //cluster number to which the i th point belongs.
    double *pClusterCenters;
    int *pNumPoints;
    double *pClusterRadii;
    
    //Functions
    
    //constructor
    KCenterClustering(int Dim,
                      int NSources,
                      double *pSources,
                      int NumClusters
                      );
    
    //destructor
    ~KCenterClustering();
    
    //k-center clustering
    void Cluster();
    
    //Compute cluster centers and the number of points in each cluster
    //and the radius of each cluster.
    
    void ComputeClusterCenters();
    
private:
    //Input Parameters
    
    int d;				//dimension of the points.
    int N;				//number of sources.
    double *px;			//pointer to sources, (d*N).
    int K;				//number of clusters
    double *dist_C;		//distances to the center.
    double *r;
    
    //Functions
    
    double ddist(const int d, const double *x, const double *y);
    int idmax(int n, double *x);
};

#endif /* KCenterClustering_hpp */
