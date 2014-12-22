_ = require('lodash')
async = require('async')
resin = require('../resin')
ui = require('../ui')
log = require('../log/log')
errors = require('../errors/errors')
permissions = require('../permissions/permissions')

exports.list = permissions.user (params) ->
	resin.models.device.getAllByApplication params.id, (error, devices) ->
		errors.handle(error) if error?

		log.out ui.widgets.table.horizontal devices, (device) ->
			device.application = device.application[0].app_name
			device.device_type = resin.device.getDisplayName(device.device_type)
			delete device.note
			delete device.supervisor_version
			delete device.uuid
			delete device.download_progress
			return device
		, [ 'ID', 'Name', 'Device Type', 'Is Online', 'IP Address', 'Application', 'Status', 'Last Seen' ]

exports.info = permissions.user (params) ->
	resin.models.device.get params.id, (error, device) ->
		errors.handle(error) if error?

		log.out ui.widgets.table.vertical device, (device) ->
			device.device_type = resin.device.getDisplayName(device.device_type)
			device.application = device.application[0].app_name
			return device
		, [
			'ID'
			'Name'
			'Device Type'
			'Is Online'
			'IP Address'
			'Application'
			'Status'
			'Last Seen'
			'UUID'
			'Commit'
			'Supervisor Version'
			'Is Web Accessible'
			'Note'
		]

exports.remove = permissions.user (params, options) ->
	ui.patterns.remove 'device', options.yes, (callback) ->
		resin.models.device.remove(params.id, callback)
	, errors.handle

exports.identify = permissions.user (params) ->
	resin.models.device.identify params.uuid, (error) ->
		errors.handle(error) if error?

# TODO: This action doesn't return any error
# if trying to rename a device that does not
# exists. This is being fixed server side.
exports.rename = permissions.user (params) ->
	async.waterfall [

		(callback) ->
			if params.name? and not _.isEmpty(params.name)
				return callback(null, params.name)
			ui.widgets.ask('How do you want to name this device?', callback)

		(name, callback) ->
			resin.models.device.rename(params.id, name, callback)

	], (error) ->
		errors.handle(error) if error?
