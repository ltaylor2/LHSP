#include "Util.hpp"

double vectorMean(std::vector<double>& v)
{
	int items = v.size();
	double sum = std::accumulate(v.begin(), v.end(), 0.0);

	return sum / items;
}

double vectorMean(std::vector<int>& v) 
{
	int items = v.size();
	double sum = std::accumulate(v.begin(), v.end(), 0.0);

	return sum / items;
}

double vectorVar(std::vector<double>& v)
{
	int items = v.size();
	double mean = vectorMean(v);
	double sqSum = 0.0;

	for (int i = 0; i < items; i++) {
		sqSum += pow(v[i]-mean, 2);
	}

	return sqSum / items;
}

double vectorVar(std::vector<int>& v)
{
	int items = v.size();
	double mean = vectorMean(v);
	double sqSum = 0.0;

	for (int i = 0; i < items; i++) {
		sqSum += pow(v[i]-mean, 2);
	}

	return sqSum / items;
}