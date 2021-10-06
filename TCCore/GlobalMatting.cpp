//
//  GlobalMatting.cpp
//  TinyCrayon
//
//  Created by Xin Zeng on 2/5/16.
//
//

#include "TCCoreLibs0.h"
#include "GlobalMatting.hpp"
using namespace cv;

struct GMSample
{
    int fi;
    int bj;
    float df;
    float db;
    float cost;
    float alpha;
    cv::Point point;
};

template <typename T>
static inline T sqr(T a)
{
    return a * a;
}

// Eq. 2
static float calculateAlpha(const cv::Vec3b &F, const cv::Vec3b &B, const cv::Vec3b &I)
{
    float result = 0;
    float div = 1e-6f;
    for (int c = 0; c < 3; ++c)
    {
        float f = F[c];
        float b = B[c];
        float i = I[c];
        
        result += (i - b) * (f - b);
        div += (f - b) * (f - b);
    }
    
    return std::min(std::max(result / div, 0.f), 1.f);
}

// Eq. 3
static float colorCost(const cv::Vec3b &F, const cv::Vec3b &B, const cv::Vec3b &I, float alpha)
{
    float result = 0;
    for (int c = 0; c < 3; ++c)
    {
        float f = F[c];
        float b = B[c];
        float i = I[c];
        
        result += sqr(i - (alpha * f + (1 - alpha) * b));
    }
    
    return sqrt(result);
}

// Eq. 4
static float distCost(const cv::Point &p0, const cv::Point &p1, float minDist)
{
    int dist = sqr(p0.x - p1.x) + sqr(p0.y - p1.y);
    return sqrt((float)dist) / minDist;
}

// for sorting the boundary pixels according to intensity
struct IntensityComp
{
    IntensityComp(const cv::Mat_<cv::Vec4b> &image) : image(image)
    {
        
    }
    
    bool operator()(const cv::Point &p0, const cv::Point &p1) const
    {
        const cv::Vec3b &c0 = RGB_VALP(image, p0);
        const cv::Vec3b &c1 = RGB_VALP(image, p1);
        
        return ((int)c0[0] + (int)c0[1] + (int)c0[2]) < ((int)c1[0] + (int)c1[1] + (int)c1[2]);
    }
    
    const cv::Mat_<cv::Vec4b> &image;
};

void calculateNearestDistance(Mat &map, const Mat &trimap, std::vector<GMSample> &samples, std::vector<cv::Point> &boundary, bool foreground, cv::Rect rect)
{
    Mat visited = Mat(trimap.size(), CV_8UC1);
    std::vector<cv::Point> vector1;
    std::vector<cv::Point> vector2;
    std::vector<cv::Point> *v1 = &vector1;
    std::vector<cv::Point> *v2 = &vector2;
    int dist = 0;
    
    visited.setTo(0);
    for (int i = 0; i < boundary.size(); i++) {
        v1->push_back(boundary[i]);
    }
    while (!v1->empty()) {
        dist++;
        for (int i=0; i<v1->size(); i++) {
            Point p = (*v1)[i];
            Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1), Point(p.x - 1, p.y - 1), Point(p.x - 1, p.y + 1), Point(p.x + 1, p.y - 1), Point(p.x + 1, p.y + 1)};
            
            for (Point &q : neighbours) {
                if (q.x < rect.x || q.x >= rect.x + rect.width || q.y < rect.y || q.y >= rect.y + rect.height)
                    continue;
                
                if (visited.at<uchar>(q))
                    continue;
                
                if ((foreground && trimap.at<uchar>(q) == 255) ||
                    (!foreground && trimap.at<uchar>(q) == 0))
                    continue;
                
                int idx = map.at<int>(cv::Point(q.x - rect.x, q.y - rect.y));
                if (idx != -1) {
                    if (foreground)
                        samples[idx].df = dist;
                    else
                        samples[idx].db = dist;
                }
                visited.at<uchar>(q) = true;
                v2->push_back(q);
            }
        }
        swap(v1, v2);
        v2->clear();
    }
}

void createSamples(Mat &map, const Mat &trimap, std::vector<Point> &trimapPoints, std::vector<cv::Point> &foregroundBoundary, std::vector<cv::Point> &backgroundBoundary, std::vector<GMSample> &samples, cv::Rect rect)
{
    samples.clear();
    for (int i = 0; i < trimapPoints.size(); i++) {
        samples.push_back(GMSample());
        GMSample &s = samples[i];
        s.fi = rand() % foregroundBoundary.size();
        s.bj = rand() % backgroundBoundary.size();
        s.cost = FLT_MAX;
        s.point = trimapPoints[i];
    }
    
    calculateNearestDistance(map, trimap, samples, foregroundBoundary, true, rect);
    calculateNearestDistance(map, trimap, samples, backgroundBoundary, false, rect);
}


void calculateAlphaPatchMatch(const Mat &image, Mat &map, std::vector<GMSample> &samples, std::vector<cv::Point> &foregroundBoundary, std::vector<cv::Point> &backgroundBoundary, cv::Rect rect)
{
    
    
    for (int iter = 0; iter < 10; ++iter)
    {
        std::vector<int> index;
        for(int i = 0; i < samples.size(); i++)
            index.push_back(i);
        
        std::random_shuffle(index.begin(), index.end());
        
        for (int i = 0; i < index.size(); i++) {
            int idx = index[i];
            GMSample &s = samples[idx];
            Point p = s.point;
            const cv::Vec3b I = RGB_VALP(image, p);
            
            // propagation
            Point neighbours[] = {p, Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
            for (Point &q : neighbours) {
                if (q.x < rect.x || q.x >= rect.x + rect.width || q.y < rect.y || q.y >= rect.y + rect.height)
                    continue;
                
                int idx2 = map.at<int>(cv::Point(q.x - rect.x, q.y - rect.y));
                if (idx2 == -1)
                    continue;
                
                GMSample &s2 = samples[idx2];
                
                const cv::Point fp = foregroundBoundary[s2.fi];
                const cv::Point bp = backgroundBoundary[s2.bj];
                
                const cv::Vec3b F = RGB_VALP(image, fp);
                const cv::Vec3b B = RGB_VALP(image, bp);
                
                float alpha = calculateAlpha(F, B, I);
                
                float cost = colorCost(F, B, I, alpha) + distCost(p, fp, s.df) + distCost(p, bp, s.db);
                
                if (cost < s.cost)
                {
                    s.fi = s2.fi;
                    s.bj = s2.bj;
                    s.cost = cost;
                    s.alpha = alpha;
                }
            }
            
            // random walk
            int w = (int)std::max(foregroundBoundary.size(), backgroundBoundary.size());
            for (int k = 0; ; k++)
            {
                float r = w * pow(0.5f, k);
                
                if (r < 1)
                    break;
                
                int di = r * (rand() / (RAND_MAX + 1.f));
                int dj = r * (rand() / (RAND_MAX + 1.f));
                
                int fi = s.fi + di;
                int bj = s.bj + dj;
                
                if (fi < 0 || fi >= foregroundBoundary.size() || bj < 0 || bj >= backgroundBoundary.size())
                    continue;
                
                const cv::Point fp = foregroundBoundary[fi];
                const cv::Point bp = backgroundBoundary[bj];
                
                const cv::Vec3b F = RGB_VALP(image, fp);
                const cv::Vec3b B = RGB_VALP(image, bp);
                
                float alpha = calculateAlpha(F, B, I);
                
                float cost = colorCost(F, B, I, alpha) + distCost(p, fp, s.df) + distCost(p, bp, s.db);
                
                if (cost < s.cost)
                {
                    s.fi = fi;
                    s.bj = bj;
                    s.cost = cost;
                    s.alpha = alpha;
                }
            }
        }
    }
}

void globalMattingHelper(const Mat &image, const Mat &trimap, Mat &alpha, cv::Rect rect)
{
    Point p;
    cv::Mat visited;
    cv::Mat map;
    std::vector<GMSample> samples;
    std::vector<cv::Point> foregroundBoundary;
    std::vector<cv::Point> backgroundBoundary;
    std::vector<cv::Point> trimapPoints;
    std::deque<cv::Point> queue;
    
    visited.create(trimap.size(), CV_8UC1);
    visited.setTo(0);
    
    map.create(rect.size(), CV_32S);
    map.setTo(-1);
    
    samples.clear();
    
    for (p.y = rect.y; p.y < rect.y + rect.height; p.y++) {
        for (p.x = rect.x; p.x < rect.x + rect.width; p.x++) {
            if (trimap.at<uchar>(p) == 128) {
                queue.push_back(p);
                map.at<int>(cv::Point(p.x - rect.x, p.y - rect.y)) = (int)trimapPoints.size();
                trimapPoints.push_back(p);
            }
        }
    }
    
    while (!queue.empty()) {
        Point p = queue.front();
        queue.pop_front();
        
        if (visited.at<uchar>(p))
            continue;
        
        visited.at<uchar>(p) = true;
        
        Point neighbours[] = {Point(p.x - 1, p.y), Point(p.x + 1, p.y), Point(p.x, p.y - 1), Point(p.x, p.y + 1)};
        
        for (Point &q : neighbours) {
            if (q.x < 0 || q.x >= trimap.cols || q.y < 0 || q.y >= trimap.rows)
                continue;
            
            if (trimap.at<uchar>(q) == 0) {
                backgroundBoundary.push_back(q);
            }
            else if (trimap.at<uchar>(q) == 255) {
                foregroundBoundary.push_back(q);
            }
            else {
                queue.push_back(q);
            }
            
        }
    }

    if (foregroundBoundary.size() == 0 || backgroundBoundary.size() == 0) {
        return;
    }
    
    createSamples(map, trimap, trimapPoints, foregroundBoundary, backgroundBoundary, samples, rect);
    
    std::sort(foregroundBoundary.begin(), foregroundBoundary.end(), IntensityComp(image));
    std::sort(backgroundBoundary.begin(), backgroundBoundary.end(), IntensityComp(image));
    
    calculateAlphaPatchMatch(image, map, samples, foregroundBoundary, backgroundBoundary, rect);
    
    for (int i = 0; i < samples.size(); i++) {
        GMSample &s = samples[i];
        cv::Point p = cv::Point(s.point.x - rect.x, s.point.y - rect.y);
        alpha.at<uchar>(p) = s.alpha * 255;
    }
}

void globalMatting(const cv::Mat &image, const cv::Mat &trimap, cv::Mat &alpha, cv::Rect rect)
{
    if (image.empty())
        CV_Error(cv::Error::StsBadArg, "image is empty");
    if (image.type() != CV_8UC4)
        CV_Error(cv::Error::StsBadArg, "image mush have CV_8UC4 type");
    
    if (trimap.empty())
        CV_Error(cv::Error::StsBadArg, "trimap is empty");
    if (trimap.type() != CV_8UC1)
        CV_Error(cv::Error::StsBadArg, "trimap mush have CV_8UC1 type");
    
    if (image.size() != trimap.size())
        CV_Error(cv::Error::StsBadArg, "image and trimap mush have same size");
    
    const double limit = 131072;
    cv::Point p;
    int count = 0;
    for (p.y = rect.y; p.y < rect.y + rect.height; p.y++)
        for (p.x = rect.x; p.x < rect.x + rect.width; p.x++)
            if (trimap.at<uchar>(p) == 128)
                count++;
    
    if (count <= limit)
        globalMattingHelper(image, trimap, alpha, rect);
    else {
        cv::Mat resizedAlpha;
        cv::Mat resizedTrimap;
        cv::Mat resizedImage;
        double factor = sqrt(alpha.cols * alpha.rows / limit);
        cv::Rect resizedRect(rect.x / factor, rect.y / factor, rect.width / factor, rect.height / factor);
        cv::resize(alpha, resizedAlpha, resizedRect.size());
        cv::resize(image, resizedImage, cv::Size(), 1.0/factor, 1.0/factor);
        cv::resize(trimap, resizedTrimap, resizedImage.size(), 0, 0, INTER_NEAREST);
        globalMattingHelper(resizedImage, resizedTrimap, resizedAlpha, resizedRect);
        cv::resize(resizedAlpha, alpha, alpha.size());
    }
}
