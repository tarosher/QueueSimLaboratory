function row=metricRow(bm,name,level,metric,ci,unit)
%METRICROW One tidy row for integrated cross-benchmark metric export.
row={bm,name,level,metric,ci.mean,ci.lower,ci.upper,ci.nValid,unit};
end
