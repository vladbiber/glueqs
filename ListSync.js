.pragma library

// Brings a ListModel in line with an array of flat objects, matched by `key`,
// so delegates survive a rescan instead of being rebuilt every few seconds.
function sync(model, arr, key) {
    var want = {};
    for (var i = 0; i < arr.length; i++) want[arr[i][key]] = i;
    for (var j = model.count - 1; j >= 0; j--)
        if (!(model.get(j)[key] in want)) model.remove(j);
    for (var k = 0; k < arr.length; k++) {
        var at = -1;
        for (var m = k; m < model.count; m++)
            if (model.get(m)[key] === arr[k][key]) { at = m; break; }
        if (at < 0) model.insert(k, arr[k]);
        else {
            if (at !== k) model.move(at, k, 1);
            model.set(k, arr[k]);
        }
    }
}
