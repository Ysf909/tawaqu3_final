import onnx

def patch(model_path, new_location):
    m = onnx.load_model(model_path, load_external_data=False)
    changed = 0
    for t in m.graph.initializer:
        if t.data_location == onnx.TensorProto.EXTERNAL:
            for kv in t.external_data:
                if kv.key == "location":
                    kv.value = new_location
                    changed += 1
    onnx.save_model(m, model_path)
    print(f"Patched {model_path} -> {new_location} (updated {changed} tensors)")

patch("ict_1m.onnx", "ict_1m.onnx.data")
patch("ict_5m.onnx", "ict_5m.onnx.data")

# verify
for mp in ["ict_1m.onnx", "ict_5m.onnx"]:
    m = onnx.load_model(mp, load_external_data=False)
    locs=set()
    for t in m.graph.initializer:
        if t.data_location == onnx.TensorProto.EXTERNAL:
            d={p.key:p.value for p in t.external_data}
            locs.add(d.get("location"))
    print(mp, "references:", sorted(locs))
