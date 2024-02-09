:white_check_mark: : Works

:x: : Doesn't work (with an * , have a deeper explanation of the error below)

:apple: : Only works building it on ARM64(Mac) computers (not simulated ARM64 on AMD64 computers)

:small_orange_diamond: : Needs to be tested

:white_circle: : Incompatibile <sup>3</sup> 	

:large_blue_circle: : Needs data

|    | Network                         | configuration.yaml   | Building AMD64     | Building ARM64     | Working AMD64          | Working GPU            | Working ARM64          |
|---:|:--------------------------------|:---------------------|:-------------------|:-------------------|:-----------------------|:-----------------------|:-----------------------|
|  0 | 3D-RCAN                         | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
|  1 | CARE (2D)                       | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :white_check_mark:     |
|  2 | CARE (3D)                       | :white_check_mark:   | :white_check_mark: | :small_orange_diamond: | :white_check_mark:     | :white_check_mark:     | :x:                    |
|  3 | Cellpose (2D and 3D)            | :white_check_mark:   | :white_check_mark: | :white_check_mark:	| :white_check_mark:     | :white_check_mark:     | :white_check_mark:     |
|  4 | CycleGAN                        | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :x:                    |
|  5 | DFCAN                           | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :x: <sup>1</sup>       | :small_orange_diamond: |
|  6 | DRMIME                          | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :large_blue_circle:    | :large_blue_circle:    | :large_blue_circle:    |
|  7 | DecoNoising (2D)                | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :x: <sup>2</sup> 	 | :x: <sup>2</sup> 	  | :x: 		   |
|  8 | Deep-STORM                      | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :white_check_mark:     |
|  9 | DenoiSeg                        | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :large_blue_circle:    | :large_blue_circle:    | :large_blue_circle:    |
| 10 | Detectron2                      | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :white_circle:         |
| 11 | EmbedSeg (2D)                   | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :white_circle:         |
| 12 | FRUNet                          | :white_check_mark:   | :white_check_mark: | :white_circle:     | :small_orange_diamond: | :small_orange_diamond: | :x: 		   |
| 13 | Label-free prediction (fnet) 2D | :white_check_mark:   | :white_check_mark: | :x:                | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
| 14 | Label-free prediction (fnet) 3D | :white_check_mark:   | :white_check_mark: | :x:                | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
| 15 | MaskRCNN (2D)                   | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :large_blue_circle:    | :large_blue_circle:    | :large_blue_circle:    |
| 16 | Noise2Void (2D)                 | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :x: 		   |
| 17 | Noise2Void (3D)                 | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :x: 		   |
| 18 | RetinaNet                       | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
| 19 | SplineDist (2D)                 | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
| 20 | StarDist (2D)                   | :white_check_mark:   | :white_check_mark: | :white_circle:     | :white_check_mark:     | :white_check_mark:     | :white_circle:         |
| 21 | StarDist (3D)                   | :white_check_mark:   | :white_check_mark: | :white_circle:     | :small_orange_diamond: | :small_orange_diamond: | :white_circle:         |
| 22 | U-Net (2D)                      | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :white_check_mark:     |
| 23 | U-Net (2D) Multilabel           | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :white_check_mark:     |
| 24 | U-Net (3D)                      | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :small_orange_diamond: |
| 25 | WGAN                            | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :small_orange_diamond: | :small_orange_diamond: | :small_orange_diamond: |
| 26 | YOLOv2                          | :white_check_mark:   | :white_check_mark: | :white_circle:     | :small_orange_diamond: | :small_orange_diamond: | :white_circle:         |
| 27 | pix2pix                         | :white_check_mark:   | :white_check_mark: | :white_check_mark: | :white_check_mark:     | :white_check_mark:     | :white_check_mark:     |

<details>
<summary> <sup>1</sup> DFCAN error:</summary>

```
2023-11-16 16:38:55.990201: I tensorflow/core/common_runtime/executor.cc:1197] [/device:CPU:0] (DEBUG INFO) Executor start aborting (this does not indicate an error and you can ignore this message): INVALID_ARGUMENT: You must feed a value for placeholder tensor 'Placeholder/_0' with dtype int32
	 [[{{node Placeholder/_0}}]]
2023-11-16 16:39:03.166374: I tensorflow/compiler/xla/stream_executor/cuda/cuda_dnn.cc:424] Loaded cuDNN version 8600
2023-11-16 16:39:03.216477: W tensorflow/compiler/xla/stream_executor/gpu/asm_compiler.cc:231] Falling back to the CUDA driver for PTX compilation; ptxas does not support CC 8.9
2023-11-16 16:39:03.216486: W tensorflow/compiler/xla/stream_executor/gpu/asm_compiler.cc:234] Used ptxas at ptxas
2023-11-16 16:39:03.216511: W tensorflow/compiler/xla/stream_executor/gpu/redzone_allocator.cc:317] UNIMPLEMENTED: ptxas ptxas too old. Falling back to the driver to compile.
Relying on driver to perform ptx compilation. 
Modify $PATH to customize ptxas location.
This message will be only logged once.
2023-11-16 16:39:03.271580: E tensorflow/compiler/xla/stream_executor/cuda/cuda_fft.cc:246] Failed to make cuFFT batched plan: 5
2023-11-16 16:39:03.271591: E tensorflow/compiler/xla/stream_executor/cuda/cuda_fft.cc:457] Initialize Params: rank: 2 elem_count: 128 input_embed: 128 input_stride: 1 input_distance: 16384 output_embed: 128 output_stride: 1 output_distance: 16384 batch_count: 512
2023-11-16 16:39:03.271592: E tensorflow/compiler/xla/stream_executor/cuda/cuda_fft.cc:466] Failed to initialize batched cufft plan with customized allocator: Failed to make cuFFT batched plan.
2023-11-16 16:39:03.271604: I tensorflow/core/common_runtime/executor.cc:1197] [/job:localhost/replica:0/task:0/device:GPU:0] (DEBUG INFO) Executor start aborting (this does not indicate an error and you can ignore this message): INTERNAL: Failed to create cuFFT batched plan with scratch allocator
	 [[{{node model/lambda_3/FFT2D}}]]
2023-11-16 16:39:03.271626: I tensorflow/core/common_runtime/executor.cc:1197] [/job:localhost/replica:0/task:0/device:CPU:0] (DEBUG INFO) Executor start aborting (this does not indicate an error and you can ignore this message): INTERNAL: Failed to create cuFFT batched plan with scratch allocator
	 [[{{node model/lambda_3/FFT2D}}]]
	 [[gradient_tape/loss_dfcan/MS-SSIM/Shape_4/_160]]

---------------------------------------------------------------------------
InternalError                             Traceback (most recent call last)
Cell In[11], line 13
      8 start = time.time()
     10 #@markdown ##Start training
     11 
     12 # Start Training
---> 13 history = model.fit(train_generator, validation_data=val_generator,
     14                       validation_steps=validation_steps,
     15                       steps_per_epoch=np.ceil(len(X_train)/batch_size),
     16                       epochs=number_of_epochs, callbacks=[model_checkpoint,lr_schedule])
     18 #model.save(os.path.join(full_model_path, 'last_model.h5'))
     19 model.save_weights(os.path.join(full_model_path, 'weights_last.h5'))

File /usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py:70, in filter_traceback.<locals>.error_handler(*args, **kwargs)
     67     filtered_tb = _process_traceback_frames(e.__traceback__)
     68     # To get the full stack trace, call:
     69     # `tf.debugging.disable_traceback_filtering()`
---> 70     raise e.with_traceback(filtered_tb) from None
     71 finally:
     72     del filtered_tb

File /usr/local/lib/python3.9/dist-packages/tensorflow/python/eager/execute.py:52, in quick_execute(op_name, num_outputs, inputs, attrs, ctx, name)
     50 try:
     51   ctx.ensure_initialized()
---> 52   tensors = pywrap_tfe.TFE_Py_Execute(ctx._handle, device_name, op_name,
     53                                       inputs, attrs, num_outputs)
     54 except core._NotOkStatusException as e:
     55   if name is not None:

InternalError: Graph execution error:

Detected at node 'model/lambda_3/FFT2D' defined at (most recent call last):
    File "/usr/lib/python3.9/runpy.py", line 197, in _run_module_as_main
      return _run_code(code, main_globals, None,
    File "/usr/lib/python3.9/runpy.py", line 87, in _run_code
      exec(code, run_globals)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel_launcher.py", line 17, in <module>
      app.launch_new_instance()
    File "/usr/local/lib/python3.9/dist-packages/traitlets/config/application.py", line 1053, in launch_instance
      app.start()
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelapp.py", line 737, in start
      self.io_loop.start()
    File "/usr/local/lib/python3.9/dist-packages/tornado/platform/asyncio.py", line 195, in start
      self.asyncio_loop.run_forever()
    File "/usr/lib/python3.9/asyncio/base_events.py", line 601, in run_forever
      self._run_once()
    File "/usr/lib/python3.9/asyncio/base_events.py", line 1905, in _run_once
      handle._run()
    File "/usr/lib/python3.9/asyncio/events.py", line 80, in _run
      self._context.run(self._callback, *self._args)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 524, in dispatch_queue
      await self.process_one()
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 513, in process_one
      await dispatch(*args)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 418, in dispatch_shell
      await result
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 758, in execute_request
      reply_content = await reply_content
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/ipkernel.py", line 426, in do_execute
      res = shell.run_cell(
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/zmqshell.py", line 549, in run_cell
      return super().run_cell(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3046, in run_cell
      result = self._run_cell(
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3101, in _run_cell
      result = runner(coro)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/async_helpers.py", line 129, in _pseudo_sync_runner
      coro.send(None)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3306, in run_cell_async
      has_raised = await self.run_ast_nodes(code_ast.body, cell_name,
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3488, in run_ast_nodes
      if await self.run_code(code, result, async_=asy):
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3548, in run_code
      exec(code_obj, self.user_global_ns, self.user_ns)
    File "/tmp/ipykernel_10368/3807974983.py", line 13, in <module>
      history = model.fit(train_generator, validation_data=val_generator,
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1685, in fit
      tmp_logs = self.train_function(iterator)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1284, in train_function
      return step_function(self, iterator)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1268, in step_function
      outputs = model.distribute_strategy.run(run_step, args=(data,))
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1249, in run_step
      outputs = model.train_step(data)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1050, in train_step
      y_pred = self(x, training=True)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 558, in __call__
      return super().__call__(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/base_layer.py", line 1145, in __call__
      outputs = call_fn(inputs, *args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 96, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/functional.py", line 512, in call
      return self._run_internal_graph(inputs, training=training, mask=mask)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/functional.py", line 669, in _run_internal_graph
      outputs = node.layer(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/base_layer.py", line 1145, in __call__
      outputs = call_fn(inputs, *args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 96, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/layers/core/lambda_layer.py", line 210, in call
      result = self.function(inputs, **kwargs)
    File "/tmp/ipykernel_10368/382404292.py", line 180, in fft2d
      fft = tf.signal.fft2d(tf.complex(temp, tf.zeros_like(temp)))
Node: 'model/lambda_3/FFT2D'
Detected at node 'model/lambda_3/FFT2D' defined at (most recent call last):
    File "/usr/lib/python3.9/runpy.py", line 197, in _run_module_as_main
      return _run_code(code, main_globals, None,
    File "/usr/lib/python3.9/runpy.py", line 87, in _run_code
      exec(code, run_globals)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel_launcher.py", line 17, in <module>
      app.launch_new_instance()
    File "/usr/local/lib/python3.9/dist-packages/traitlets/config/application.py", line 1053, in launch_instance
      app.start()
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelapp.py", line 737, in start
      self.io_loop.start()
    File "/usr/local/lib/python3.9/dist-packages/tornado/platform/asyncio.py", line 195, in start
      self.asyncio_loop.run_forever()
    File "/usr/lib/python3.9/asyncio/base_events.py", line 601, in run_forever
      self._run_once()
    File "/usr/lib/python3.9/asyncio/base_events.py", line 1905, in _run_once
      handle._run()
    File "/usr/lib/python3.9/asyncio/events.py", line 80, in _run
      self._context.run(self._callback, *self._args)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 524, in dispatch_queue
      await self.process_one()
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 513, in process_one
      await dispatch(*args)
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 418, in dispatch_shell
      await result
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/kernelbase.py", line 758, in execute_request
      reply_content = await reply_content
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/ipkernel.py", line 426, in do_execute
      res = shell.run_cell(
    File "/usr/local/lib/python3.9/dist-packages/ipykernel/zmqshell.py", line 549, in run_cell
      return super().run_cell(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3046, in run_cell
      result = self._run_cell(
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3101, in _run_cell
      result = runner(coro)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/async_helpers.py", line 129, in _pseudo_sync_runner
      coro.send(None)
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3306, in run_cell_async
      has_raised = await self.run_ast_nodes(code_ast.body, cell_name,
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3488, in run_ast_nodes
      if await self.run_code(code, result, async_=asy):
    File "/usr/local/lib/python3.9/dist-packages/IPython/core/interactiveshell.py", line 3548, in run_code
      exec(code_obj, self.user_global_ns, self.user_ns)
    File "/tmp/ipykernel_10368/3807974983.py", line 13, in <module>
      history = model.fit(train_generator, validation_data=val_generator,
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1685, in fit
      tmp_logs = self.train_function(iterator)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1284, in train_function
      return step_function(self, iterator)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1268, in step_function
      outputs = model.distribute_strategy.run(run_step, args=(data,))
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1249, in run_step
      outputs = model.train_step(data)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 1050, in train_step
      y_pred = self(x, training=True)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/training.py", line 558, in __call__
      return super().__call__(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/base_layer.py", line 1145, in __call__
      outputs = call_fn(inputs, *args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 96, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/functional.py", line 512, in call
      return self._run_internal_graph(inputs, training=training, mask=mask)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/functional.py", line 669, in _run_internal_graph
      outputs = node.layer(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 65, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/engine/base_layer.py", line 1145, in __call__
      outputs = call_fn(inputs, *args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/utils/traceback_utils.py", line 96, in error_handler
      return fn(*args, **kwargs)
    File "/usr/local/lib/python3.9/dist-packages/keras/layers/core/lambda_layer.py", line 210, in call
      result = self.function(inputs, **kwargs)
    File "/tmp/ipykernel_10368/382404292.py", line 180, in fft2d
      fft = tf.signal.fft2d(tf.complex(temp, tf.zeros_like(temp)))
Node: 'model/lambda_3/FFT2D'
2 root error(s) found.
  (0) INTERNAL:  Failed to create cuFFT batched plan with scratch allocator
	 [[{{node model/lambda_3/FFT2D}}]]
	 [[gradient_tape/loss_dfcan/MS-SSIM/Shape_4/_160]]
  (1) INTERNAL:  Failed to create cuFFT batched plan with scratch allocator
	 [[{{node model/lambda_3/FFT2D}}]]
0 successful operations.
0 derived errors ignored. [Op:__inference_train_function_33231]
```
</details>


<details>
<summary> <sup>2</sup> DecoNoising error:</summary>
	Problems with the GitHub repository pn2v (https://github.com/juglab/pn2v). Due to a change in the code, the **pn2v** folder is now in a **src**, breaking all the imports that are **from pn2v**, even the ones that *deconosing** has.
</details>

<details>
<summary> <sup>3</sup> Code incompatibility </summary>
	- Some workflows are compiled for GPU usage using CUDA, which impedes the usage of the notebook in the absence of a GPU. In these cases, an error such as `Torch not compiled with CUDA enabled.` is frequent.
	- Lack of compatibility with ARM64 systems appears often with old code/dependencies as back in the time they were not compiled for this system architecture.
</details>
